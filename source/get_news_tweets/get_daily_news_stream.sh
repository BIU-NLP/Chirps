consumer_key='YOUR_KEY_HERE'
consumer_secret='YOUR_KEY_HERE'
access_token='YOUR_KEY_HERE'
access_token_secret='YOUR_KEY_HERE'
dropbox_access_token='YOUR_KEY_HERE'
repository_dir='REPOSITORY_DIR'

while true; do 
	
	while [ $(date +%H:%M) != "00:00" ]; do
		sleep 59
  done
  
  # Start collecting news for the next day
  pkill -f get_news_tweets_stream.py;
  python -u get_news_tweets_stream.py $consumer_key $consumer_secret $access_token $access_token_secret &
  
  # Get propositions and positive instances for the previous day, package and release a new version of the resource
  last_file=`date -d "yesterday" '+%Y_%m_%d'`;
  (python -u prop_extraction.py --in=news_stream/tweets/$last_file --out=news_stream/props/$last_file.prop > prop.log;
  python -u get_corefering_predicates.py news_stream/props/$last_file.prop news_stream/positive/$last_file;
  cat news_stream/positive/* | cut -f1,2,4,5,6,7,8,10,11,12,13,14 > resource;
  python -u package_resource.py resource resource_dir;
  zip resource_dir/resource.zip resource_dir/*.tsv;
  python upload_to_dropbox.py $dropbox_access_token resource_dir;
  cp resource_dir/resource.zip $repository_dir/resource;
  git --git-dir=$repository_dir/.git pull;
  git --git-dir=$repository_dir/.git --work-tree=$repository_dir/ commit -m "update resource; #instances: `wc -l instances.tsv`; #rules: `wc -l rules.tsv`" resource/*;
  git --git-dir=$repository_dir/.git --work-tree=$repository_dir/ push origin master) &
  
  # Sleep before checking again...
  sleep 60
done
