phony target有两种作用：
1，防止同名文件，使得规则总是被执行
2.改进性能


1.PHONY:clean
这里clean目标没有依赖文件，如果执行make命令的目录中出现了clean文件，由于其没有依赖文件，所以它永远是最新的，所以根据make的规则clean目标下的命令是不会被执行的。如下的
2.改进性能
这是在调用子make的时候用的
SUBDIRS = foo bar baz

subdirs:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir; \
	done

当其中一个出错的时候，make运行一直到循环结束，假如我们需要在其中出错的时候，就停下，这个时候就需要借助用.PHONY
SUBDIRS = foo bar baz
.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

foo: baz
