from math import *

def sign(x):
    return floor(x / (abs(x) + 1)) + ceil(x / (abs(x) + 1))

def at(x, b, i):
  return floor(abs(x) / (b ** i)) % b

def eq(x, y):
    return 1 - ceil(abs(x - y) / (abs(x - y) + 1))

def lt(x, y):
    return eq(-1, sign(x - y))

def len(x, b):
  return ceil(log(x + 1, b))

def sigma_eq(x, b, i):
    return sum(eq(at(x, b, j), at(x, b, i)) for j in range(0, i))

def sigma_lt(x, b, i):
    return sum(lt(at(x, b, j), at(x, b, i)) for j in range(0, len(x, b)))

def sigma_sort(x, b, i):
    return sigma_eq(x, b, i) + sigma_lt(x, b, i)

def sort(x, b):
    return sum(at(x, b, i) * 10 ** sigma_sort(x, b, i) for i in range(len(x, b)))


print(sort(315204, 10))

