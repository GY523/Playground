from copy import copy
from copy import deepcopy
from sys import getsizeof

print('-'* 30)
print("shallow copies vs deep copies")
print('-' * 30)
lst = ['a','A','B']
print(f'{id(lst)=}')
lst2 = lst.copy()
print(f'{ id(lst2)=}')
print(f'{id(lst[0])==id(lst2[0])=}')
print(f'{id(lst[1]) == id(lst2[1])=}')

print('\nDeep Copy:')
lst2 = deepcopy(lst)
print(f'{id(lst)=}')
lst2 = lst.copy()
print(f'{ id(lst2)=}')
print(f'{id(lst[0])==id(lst2[0])=}')
print(f'{id(lst[1]) == id(lst2[1])=}')

lst2[0] = "C"
print(f'{id(lst[0])==id(lst2[0])=}')


print('-'* 30)
print("list literal to convert a iterator")
print('-' * 30)

def fibonacci_generator(stop):
    current_fib, next_fib = 0, 1
    for _ in range(stop):
        current_fib, next_fib = next_fib, current_fib + next_fib
        yield current_fib

print(list(fibonacci_generator(10)))

print('-'* 30)
print("slicing operation")
print('-' * 30)

letters = ['a','A','b',"B",'c',"C",'d',"D"]

# every slicing operations use slice object internally. Built-in function slice return a slide object.
lower_case = letters[slice(0,None,2)]

upper_case = letters[slice(1,None,2)]

print('-'* 30)
print(" Append the list ")
print('-' * 30)
fruits = ['apple', 'banana', 'watermelon']
print(fruits)
print('with slice assignment')
fruits[len(fruits):] = ['peach']
print(fruits)

print('with append method')
fruits.append('pineapple')
print(fruits)

print('-' * 30)
print(" extend the list")
print('-' * 30)

fruits = ['apple', 'banana', 'watermelon']
print(fruits)
fruits.extend(['pineapple', 'avocado'])
fruits[len(fruits):] = ['peach', 'durian']
print(fruits)

print('-' * 30)
print("slice assignment")
print('-' * 30)

numbers = [1,2,3,4,5,6,7]
print(numbers)
numbers[1:4] = [2]
print(numbers)
numbers[1:4] = [23,4,5,5]
print(numbers)
print("it seems like slicing assignment doesn't care about the number of elements,\
      it automaticallys shrink or grow. it only depends on the the range elements being \
      specified for replacement, and just replace the elements with the given list into the start of the \
      range.")

print('-' * 30)
print("Reversed and sorted")
print('-' * 30)

numbers = [1,2,3]
print("reversed() returns an iterator which used to iterate a list in reversed order\
    without changing the content")
reversed_number = reversed(numbers)
print(next(reversed_number))

numbers[1] = 2222
print(next(reversed_number))
print(next(reversed_number))

print('.sort() with a lambda as a key argument')
employees = [
     ("John", 30, "Designer", 75000),
     ("Jane", 28, "Engineer", 60000),
     ("Bob", 35, "Analyst", 50000),
     ("Mary", 25, "Service", 40000),
     ("Tom", 40, "Director", 90000)
 ]

employees.sort(key = lambda employee: employee[1])
print(employees)

print('-' * 30)
print('use filter and map function for list')
print('-' * 30)
print(list(filter(lambda x: x%2==1, numbers )))
print('map:')
print(list(map(str,numbers)))