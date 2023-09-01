This generates the commands to delete inactive access keys in your account.

```sh
for userName in $(aws iam list-users --query "Users[].UserName" --output text); do
	for accessKeyId in $(aws iam list-access-keys --user-name $userName --query "AccessKeyMetadata[?Status=='Inactive'].AccessKeyId" --output text); do
		echo aws iam delete-access-key --access-key-id $accessKeyId --user-name $userName
	done
done
```
