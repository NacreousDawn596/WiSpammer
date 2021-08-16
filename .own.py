import os
def start():
	global name
	name = input("what do you want to name the file? \n->" + ".txt")
	print(name)
	yn = input("modify the name? y/n\n->")
	if yn == "n":
		start()
	else:
		pass
command = f"touch {name} && echo 'enter a name on every line and delete this line' >> {name} && echo {name} > .conf"
os.system(command)
command = f"gedit {name}"
os.system(command)