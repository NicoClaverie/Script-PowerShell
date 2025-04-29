$QuelCommit = Read-Host "Commit ?"
git add .
git commit -m "$QuelCommit"
git push