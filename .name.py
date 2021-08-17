import random
string = "a z e r t y u i o p m l k j h g f d s q w x c v b n A Z E R T Y U I O P M L K J H G F D S Q W X C V B N 0 9 8 7 6 5 4 3 2 1"
string = string.split()
random.shuffle(string)
result = string[5]
for _ in range(5):
	random.shuffle(string)
	result = f"{result}{string[5]}"
file = open(".conf", 'w')
file.write(''.join(result))