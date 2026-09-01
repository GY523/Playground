class Dog:
    # class attributes
    species = "Canis familiaris"

    def __init__(self, name, age):
        self.name = name
        self.age = age
        # added a breed 
        # self.breed = breed

    def __str__(self):
        return f'{self.name} is {self.age} years old'

    def speak (self, sound):
        return f'{self.name} barks: {sound}'

# Create 4 different dogs
# miles = Dog('miles', 10, "Jack RUssell Terrier")
# buddy = Dog('Buddy', 9, "Dachshund")
# jack = Dog('Jack', 3, "Bulldog")
# jim = Dog ('Jim', 5, "Bulldog")

# Dog bark has different sounds based on breed, but now we have to manually add the sound
# buddy.speak('Yap')
# jim.speak('Woof')
# jack.speak('Woof')

# it is inconvenient currently, moreover, the breed should determine the sound dog instance makes.

# Solution: Create child class for each breed of dog
class JackRussellTerrier(Dog):
    def speak(self, sound="Arf"):
        #return f'{self.name} says {sound}'
        # to make the format of the string follows when updating the parent class, call parent method
        return super().speak(sound)
    
class Dachshund(Dog):
    pass 

class Bulldog(Dog):
    pass

miles = JackRussellTerrier("Miles", 4)
buddy = Dachshund("Buddy", 9)
jack = Bulldog('Jack', 3)
jim = Bulldog ('Jim', 5)

print(miles.species)
print(miles.speak())
print(jack)
print(jim.speak("Woof"))



#print(miles.description())
print(miles)
#print(miles.speak("WOwo Bow"))

a = Dog("maria", 9)