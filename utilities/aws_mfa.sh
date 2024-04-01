aws_sts_info=$(aws sts get-session-token --serial-number $1 --token-code $2)
aws_session_token=$(echo ${aws_sts_info} | jq -r .Credentials.SessionToken)
aws configure --profile ${3:-default} set aws_session_token $aws_session_token

echo "AWS Session is set!"