"""Explicit, resumable campaign publication; credentials never enter output files."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shlex
import sys
import requests

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
STATE = ROOT / 'publication-state.json'
BASE = 'https://graph.facebook.com/v25.0/'
EXPECTED = 'inventingfire_with_ai'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['check', 'create', 'status', 'publish', 'verify'])
    parser.add_argument('--revision')
    args = parser.parse_args()
    credentials = {}
    for line in Path('/Users/rich/.config/promote-product/credentials.env').read_text().splitlines():
        if line.strip() and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            credentials[key.strip()] = shlex.split(value)[0]
    session = requests.Session()
    session.headers['Authorization'] = 'Bearer ' + credentials['INSTAGRAM_ACCESS_TOKEN']
    account = credentials['IG_USER_ID']

    def call(path, data=None, **params):
        try:
            response = session.get(BASE + path, params=params, timeout=45) if data is None else session.post(BASE + path, data=data, timeout=45)
            result = response.json()
        except (requests.RequestException, ValueError):
            raise RuntimeError('Ambiguous network response; reconcile state before retrying.') from None
        if not response.ok:
            error = result.get('error', {})
            raise RuntimeError(f"Graph HTTP {response.status_code}; code {error.get('code')}; subcode {error.get('error_subcode')}")
        return result

    identity = call(account, fields='id,username,name')
    assert identity['username'] == EXPECTED, 'Wrong account; refusing publication'
    if args.action == 'check':
        permissions = call('me/permissions')['data']
        granted = {p['permission'] for p in permissions if p['status'] == 'granted'}
        required = {'instagram_basic', 'instagram_content_publish', 'pages_read_engagement'}
        assert required <= granted, 'Missing publishing scopes'
        print(json.dumps({'account': identity, 'required_scopes_granted': sorted(required), 'quota': call(account + '/content_publishing_limit')}, indent=2))
        return

    state = json.loads(STATE.read_text()) if STATE.exists() else {'account': identity, 'children': []}
    assert state['account']['id'] == identity['id']
    def save():
        STATE.write_text(json.dumps(state, indent=2) + '\n')
    caption = (ROOT / 'caption.txt').read_text().strip()
    alts = json.loads((ROOT / 'alt-text.json').read_text())
    assert '@richcrane' in caption and 'v2.0.1' in caption and len(caption) <= 2200
    assert len(alts) == 6 and all(len(a) <= 1000 for a in alts)
    if args.action == 'create':
        assert not state.get('parent') and not state.get('publish_attempted'), 'Existing campaign state; use status or verify'
        revision = state.get('revision') or args.revision
        assert revision and re.fullmatch('[0-9a-f]{40}', revision)
        state['revision'] = revision
        save()
        for i in range(len(state['children']), 6):
            filename = f'slide-{i+1:02d}.jpg'
            url = f'https://raw.githubusercontent.com/ChiefInnovator/cutandmove/{revision}/{ROOT.relative_to(REPO).as_posix()}/{filename}'
            response = requests.get(url, timeout=30)
            assert response.ok and response.content == (ROOT / filename).read_bytes(), 'Hosted image differs'
            assert response.content[:2] == b'\xff\xd8' and len(response.content) < 8_000_000
            result = call(account + '/media', data={'image_url': url, 'is_carousel_item': 'true', 'alt_text': alts[i], 'user_tags': json.dumps([{'username': 'richcrane', 'x': 0.17, 'y': 0.94}])})
            state['children'].append({'slide': i+1, 'container_id': result['id'], 'url': url, 'sha256': hashlib.sha256(response.content).hexdigest()})
            save()
            print('Created slide', i+1, result['id'], flush=True)
        state['parent'] = call(account + '/media', data={'media_type': 'CAROUSEL', 'children': ','.join(c['container_id'] for c in state['children']), 'caption': caption, 'is_ai_generated': 'true'})['id']
        save()
        print('Parent', state['parent'])
    elif args.action == 'status':
        print(call(state['parent'], fields='status_code'))
    elif args.action == 'publish':
        assert not state.get('publish_attempted'), 'Already attempted; reconcile, never blindly republish'
        assert call(state['parent'], fields='status_code')['status_code'] == 'FINISHED'
        state['publish_attempted'] = True
        save()
        state['post_id'] = call(account + '/media_publish', data={'creation_id': state['parent']})['id']
        save()
        print('Published ID', state['post_id'])
    else:
        if not state.get('post_id'):
            matches = [p for p in call(account + '/media', fields='id,caption,permalink', limit=25)['data'] if p.get('caption') == caption]
            assert len(matches) == 1, 'Cannot uniquely reconcile; do not republish'
            state['post_id'] = matches[0]['id']
        result = call(state['post_id'], fields='id,username,caption,permalink,media_type,children{id,media_type,media_url,alt_text}')
        assert result['username'] == EXPECTED and result['caption'] == caption
        assert result['media_type'] == 'CAROUSEL_ALBUM' and len(result['children']['data']) == 6
        assert [c.get('alt_text') for c in result['children']['data']] == alts, 'Published alt text or slide order mismatch'
        state['verified'] = {k: v for k, v in result.items() if k != 'children'}
        state['published_children'] = [c['id'] for c in result['children']['data']]
        state['alt_text_and_order_verified'] = True
        # Preserve returned order for visual checking, but never retain temporary CDN URLs.
        verification = REPO / 'build/promotion-2.0.1-verification'
        verification.mkdir(parents=True, exist_ok=True)
        for i, child in enumerate(result['children']['data'], 1):
            response = requests.get(child['media_url'], timeout=45)
            response.raise_for_status()
            (verification / f'published-{i:02d}.jpg').write_bytes(response.content)
        save()
        print(json.dumps(state['verified'], indent=2))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Raw exceptions may contain signed URLs; only our sanitized Graph failures are printable.
        print(str(error) if isinstance(error, (RuntimeError, AssertionError)) else type(error).__name__ + ': operation failed; inspect safe state')
        sys.exit(1)
