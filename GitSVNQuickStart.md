### How to clone our codebase ###
```
  git svn clone http://xxx.xxx.xxx/trunk
```

### How to setup your local git svn repo ###
```
  git svn init --stdlayout http://xxx.xxx.xxx
  git fetch
```

### How to update your current codebase ###
```
  git svn rebase
```

### How to make changes and commit ###
```
  git add xxx   # this will stage your changes
  git commit    # this will commit your changes to your local git repo
  git svn dcommit  # this will push the diffs between your git head and remote/git-svn to the remote svn repo and update your local repo to the latest svn head
```

### How to make tag/branch ###
```
  git svn reset -r<n> # choose the svn revision you want to tag/branch for
  git svn tag -m "xxxxx" mytag
  git svn branch -m "xxxx" mybranch
```

### How to checkout specific revision ###
```
   git checkout <revision-commint-sha>
```

### How to push local commits into different svn branch ###
```
  git rebase remotes/xxx
  git svn dcommit --dry-run # this check if the commits go to the right remote branch
  git svn dcommit
```

### How to find more helps ###
```
  git help svn
```