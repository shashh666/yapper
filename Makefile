build:
	rm -rf public
	hugo 

deploy: build
	aws s3 sync public/ s3://yapper.io --acl public-read --delete
	aws configure set preview.cloudfront true 
	aws cloudfront create-invalidation --distribution-id E3GYNX5AF33F4Q --paths '/*'
