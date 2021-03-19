cd frontend
yarn build
aws --profile analyze s3 sync ./dist s3://ecologica-cliente/ --acl public-read --cache-control max-age=600
aws --profile analyze s3 sync ./dist/index.html s3://ecologica-cliente/ --acl public-read --cache-control max-age=60

aws cloudfront create-invalidation --distribution-id E1QRM1JFRHDILR --paths "/*" --profile analyze 

cd ..
cd backend
sls deploy -s prod function -f principal

