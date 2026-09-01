class Parent:
    hair_color = "brown"
    speak = ['English']

class Child(Parent):
    #Child class can override and extend the attrib and methods of parent class.
    hair_color = "purple"

    def __init__(self):
        super().__init__()
        self.speaks = Parent.speaks + ['German']
a = Child()
print(a.hair_color)