"""Explicit, resumable Instagram campaign publication. No automatic publish retries."""
import argparse
import json
from pathlib import Path
import shlex
import sys
import requests

ROOT = Path(__file__).resolve().parent
STATE = ROOT / 'publication-state.json'
BASE = 'https://graph.facebook.com/v26.0/'
EXPECTED = 'inventingfire_with_ai'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=['create','status','publish','verify'])
    parser.add_argument('--revision')
    args=parser.parse_args()
    credentials={k.strip():shlex.split(v)[0] for line in Path('/Users/rich/.config/promote-product/credentials.env').read_text().splitlines() if line.strip() and not line.lstrip().startswith('#') for k,v in [line.split('=',1)]}
    session=requests.Session()
    session.headers['Authorization']='Bearer '+credentials['INSTAGRAM_ACCESS_TOKEN']
    account=credentials['IG_USER_ID']
    def call(path, data=None, **params):
        try:
            response=session.get(BASE+path,params=params,timeout=45) if data is None else session.post(BASE+path,data=data,timeout=45)
            result=response.json()
        except (requests.RequestException,ValueError):
            raise RuntimeError('Ambiguous network response. Reconcile existing state before retrying.') from None
        if not response.ok:
            error=result.get('error',{})
            raise RuntimeError(f"Graph HTTP {response.status_code}; code {error.get('code')}; subcode {error.get('error_subcode')}")
        return result
    identity=call(account,fields='id,username,name')
    assert identity['username']==EXPECTED, 'Wrong account; refusing publication'
    state=json.loads(STATE.read_text()) if STATE.exists() else {'account':identity,'children':[]}
    def save():
        STATE.write_text(json.dumps(state,indent=2)+'\n')
    caption=(ROOT/'caption.txt').read_text().strip()
    alt=json.loads((ROOT/'alt-text.json').read_text())
    assert '@richcrane' in caption and len(caption)<=2200
    assert len(alt)==6 and all(len(a)<=1000 for a in alt)
    if args.action=='create':
        assert not state.get('parent') and not state.get('publish_attempted'), 'Existing parent; use status/verify'
        revision=state.get('revision') or args.revision
        assert revision and len(revision)==40
        state['revision']=revision
        save()
        for i in range(len(state['children']),6):
            url=f'https://raw.githubusercontent.com/ChiefInnovator/cutandmove/{revision}/outputs/promote-product/cutandmove/1.0.2/20260905T190121Z/slide-{i+1:02d}.jpg'
            response=requests.get(url,timeout=30)
            assert response.ok and response.content[:2]==b'\xff\xd8' and len(response.content)<8_000_000
            result=call(account+'/media',data={'image_url':url,'is_carousel_item':'true','alt_text':alt[i],'user_tags':json.dumps([{'username':'richcrane','x':0.16,'y':0.94}])})
            state['children'].append({'slide':i+1,'container_id':result['id'],'url':url})
            save()
            print('Created slide',i+1,result['id'],flush=True)
        state['parent']=call(account+'/media',data={'media_type':'CAROUSEL','children':','.join(c['container_id'] for c in state['children']),'caption':caption,'is_ai_generated':'true'})['id']
        save()
        print('Parent',state['parent'])
    elif args.action=='status':
        print(call(state['parent'],fields='status_code'))
    elif args.action=='publish':
        assert not state.get('publish_attempted'), 'Already attempted; reconcile with verify, never blindly republish'
        assert call(state['parent'],fields='status_code')['status_code']=='FINISHED'
        # Durable attempt marker precedes the request to prevent accidental duplication.
        state['publish_attempted']=True
        save()
        state['post_id']=call(account+'/media_publish',data={'creation_id':state['parent']})['id']
        save()
        print('Published ID',state['post_id'])
    else:
        if not state.get('post_id'):
            candidates=call(account+'/media',fields='id,caption,permalink',limit=25)['data']
            matches=[p for p in candidates if p.get('caption')==caption]
            assert len(matches)==1, 'Cannot reconcile uniquely; do not retry publication'
            state['post_id']=matches[0]['id']
        result=call(state['post_id'],fields='id,username,caption,permalink,media_type,children{id,media_type,media_url}')
        assert result['username']==EXPECTED and result['caption']==caption
        assert result['media_type']=='CAROUSEL_ALBUM' and len(result['children']['data'])==6
        # Signed CDN URLs are temporary, not useful durable campaign records.
        state['verified']={k:v for k,v in result.items() if k!='children'}
        state['published_children']=[c['id'] for c in result['children']['data']]
        save()
        print(json.dumps(state['verified'],indent=2))

if __name__=='__main__':
    try:
        main()
    except Exception as error:
        print(type(error).__name__+': '+str(error))
        sys.exit(1)
