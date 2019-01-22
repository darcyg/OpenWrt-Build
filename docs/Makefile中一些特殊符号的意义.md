命令行以'@'打头：在执行到的时候不回显相应的命令内容，只显示命令的输出。
命令行以'-'打头：在执行到的时候如果发生错误（退出返回非零状态）时，不中断make过程。
命令行以'+'打头： makefile中以+开头的命令的执行不受到 make的-n,-t,-q三个参数的影响。我们知道，在make的时候，如果加上-n, -t, -q这样的参数，都是不执行相应命令的，而以'+'开头的命令，则无论make命令后面是否跟着三个参数，都会被执行。

附：make命令参数

 

make的参数 

下面列举了所有GNU make 3.80版的参数定义。其它版本的make大同小异，不过其它厂商的make的具体参数还是请参考各自的产品文档。 

“-b” 
“-m” 
这两个参数的作用是忽略和其它版本make的兼容性。 

“-B” 
“--always-make” 
认为所有的目标都需要更新（重编译）。 

“-C <dir>;” 
“--directory=<dir>;” 
指定读取makefile的目录。如果有多个“-C”参数，make的解释是后面的路径以前面的作为相对路径，并以最后的目录作为被指定目录。如：“make –C ~hchen/test –C prog”等价于“make –C ~hchen/test/prog”。 

“—debug[=<options>;]” 
输出make的调试信息。它有几种不同的级别可供选择，如果没有参数，那就是输出最简单的调试信息。下面是<options>;的取值： 
    a —— 也就是all，输出所有的调试信息。（会非常的多） 
    b —— 也就是basic，只输出简单的调试信息。即输出不需要重编译的目标。 
    v —— 也就是verbose，在b选项的级别之上。输出的信息包括哪个makefile被解析，不需要被重编译的依赖文件（或是依赖目标）等。 
    i —— 也就是implicit，输出所以的隐含规则。 
    j —— 也就是jobs，输出执行规则中命令的详细信息，如命令的PID、返回码等。 
    m —— 也就是makefile，输出make读取makefile，更新makefile，执行makefile的信息。 

“-d” 
相当于“--debug=a”。 

“-e” 
“--environment-overrides” 
指明环境变量的值覆盖makefile中定义的变量的值。 

“-f=<file>;” 
“--file=<file>;” 
“--makefile=<file>;” 
指定需要执行的makefile。 

“-h” 
“--help” 
显示帮助信息。 

“-i” 
“--ignore-errors” 
在执行时忽略所有的错误。 

“-I <dir>;” 
“--include-dir=<dir>;” 
指定一个被包含makefile的搜索目标。可以使用多个“-I”参数来指定多个目录。 

“-j [<jobsnum>;]” 
“--jobs[=<jobsnum>;]” 
指同时运行命令的个数。如果没有这个参数，make运行命令时能运行多少就运行多少。如果有一个以上的“-j”参数，那么仅最后一个“-j”才是有效的。（注意这个参数在MS-DOS中是无用的） 

“-k” 
“--keep-going” 
出错也不停止运行。如果生成一个目标失败了，那么依赖于其上的目标就不会被执行了。 

“-l <load>;” 
“--load-average[=<load]” 
“—max-load[=<load>;]” 
指定make运行命令的负载。 

“-n” 
“--just-print” 
“--dry-run” 
“--recon” 
仅输出执行过程中的命令序列，但并不执行。 

“-o <file>;” 
“--old-file=<file>;” 
“--assume-old=<file>;” 
不重新生成的指定的<file>;，即使这个目标的依赖文件新于它。 

“-p” 
“--print-data-base” 
输出makefile中的所有数据，包括所有的规则和变量。这个参数会让一个简单的makefile都会输出一堆信息。如果你只是想输出信息而不想执行makefile，你可以使用“make -qp”命令。如果你想查看执行makefile前的预设变量和规则，你可以使用“make –p –f /dev/null”。这个参数输出的信息会包含着你的makefile文件的文件名和行号，所以，用这个参数来调试你的makefile会是很有用的，特别是当你的环境变量很复杂的时候。 

“-q” 
“--question” 
不运行命令，也不输出。仅仅是检查所指定的目标是否需要更新。如果是0则说明要更新，如果是2则说明有错误发生。 

“-r” 
“--no-builtin-rules” 
禁止make使用任何隐含规则。 

“-R” 
“--no-builtin-variabes” 
禁止make使用任何作用于变量上的隐含规则。 

“-s” 
“--silent” 
“--quiet” 
在命令运行时不输出命令的输出。 

“-S” 
“--no-keep-going” 
“--stop” 
取消“-k”选项的作用。因为有些时候，make的选项是从环境变量“MAKEFLAGS”中继承下来的。所以你可以在命令行中使用这个参数来让环境变量中的“-k”选项失效。 

“-t” 
“--touch” 
相当于UNIX的touch命令，只是把目标的修改日期变成最新的，也就是阻止生成目标的命令运行。 

“-v” 
“--version” 
输出make程序的版本、版权等关于make的信息。 

“-w” 
“--print-directory” 
输出运行makefile之前和之后的信息。这个参数对于跟踪嵌套式调用make时很有用。 

“--no-print-directory” 
禁止“-w”选项。 

“-W <file>;” 
“--what-if=<file>;” 
“--new-file=<file>;” 
“--assume-file=<file>;” 
假定目标<file>;需要更新，如果和“-n”选项使用，那么这个参数会输出该目标更新时的运行动作。如果没有“-n”那么就像运行UNIX的“touch”命令一样，使得<file>;的修改时间为当前时间。 

“--warn-undefined-variables” 
只要make发现有未定义的变量，那么就输出警告信息。 
 