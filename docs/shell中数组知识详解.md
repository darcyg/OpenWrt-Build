shell数组的知识：

1、数组用括号来表示，元素用"空格"符号分割开，语法格式如下：array_name=(value1 ... valuen)
$ array=(Nanjing Wuxi Xuzhou Changzhou Suzhou)

2、读取数组元素值的一般格式是：${array_name[index]}，下标从0开始
$ echo ${array[0]}
Nanjing
$ echo ${array[3]}
Changzhou

3、@ 或 * 可以获取数组中的所有元素，例如：${my_array[@]}或${my_array[*]}
$ echo ${array[@]}
Nanjing Wuxi Xuzhou Changzhou Suzhou
$ echo ${array[*]}
Nanjing Wuxi Xuzhou Changzhou Suzhou

4、获取数组元素个数：${#my_array[@]}或${#my_array[*]}
$ echo ${#array[@]}
5
$ echo ${#array[*]}
5
