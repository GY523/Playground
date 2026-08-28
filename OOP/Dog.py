class Dog:
    # class attributes
    species = "Canis familiaris"

    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __str__(self):
        return f'{self.name} is {self.age} years old'

    def speak (self, sound):
        return f'{self.name} says {sound}'

miles = Dog('miles', 10)
#print(miles.description())
print(miles)
print(miles.speak("WOwo Bow"))

a = Dog("maria", 9)