class Car:
    def __init__(self, color, mileage):
        self.color = color
        self.mileage = mileage

    def __str__(self):
        return f'The {self.color} car has {self.mileage:,} miles'

car1 = Car('blue', 20000)
car2 = Car('red', 30000)

print(car1)
print(car2)