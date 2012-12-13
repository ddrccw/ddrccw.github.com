##ddrccw's library##

###Prerequisites###

* Ruby (only tested with 1.9)及相关组件

	gem install nokogiri sass growl
	
###Install###

1. `git clone https://github.com/ddrccw/ddrccw.github.com.git ddrccw`

	ddrccw 为blog根目录，可随意更改名称

2. `cd ddrccw`
3. `mkdir _cache`

	_cache       //如果你有自己的开源项目，参考_config.yml里的写法，会自动将项目的README.md download放置其中，最终build出一个适合本站主题的README页面

4. `git clone https://github.com/ddrccw/ddrccw.github.com.git _compiled`

	_compiled    //当jekyll生成html到_site后，同步到该目录，再推送至github下的个人blog，名字对应于Rakefile中的命名

5. `git checkout --track origin/source`

	source       //分支，专门用来编辑blog的html等


考虑到github不支持自定义插件  jekyll safe是开启状态，只能本地先合成html，再推送至github

基本想法：git clone两次，在source分支中编辑blog的相关的内容，在_compile里checkout至master，将由source分支中jekll合成的html同步到_compile，最后git commit到github服务端的master下。

###Rakefile###

1. `rake build`      用jekyll合成站点页面

2. `rake ssend`      pushes the compiled version to github.

3. `rake send`       pushes the compiled version to github, after deleted the cache.

4. `rake kill`       本地jekyll调试后，kill掉状态为T的jekyll和rake进程。

5. `rake localtest`  本地jekyll调试用。

6. `rake new article-title`  自动生成一个模板编辑页面，并用Mou打开

***ps:***

1. source分支的更新，直接在source分支下`git push origin HEAD`或`rake update`

2. master的更新，在source分支下rake ssend
    

###Licence###

[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-nc-sa/3.0/deed.zh)



copy right @ ddrccw  |  主题由[Bilal Syed Hussain](http://bilalh.github.com)提供
