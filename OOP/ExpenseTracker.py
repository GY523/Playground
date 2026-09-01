class Expense:
    def __init__(self, description, amount:float, datetime ):
        self.id = int()
        self.description = description
        self.amount = amount
        self.category = Category()
        self.datetime = datetime

    def __str__(self):
        return f'{self.id}\n {self.description}\n {self.amount}\n {self.category}\n {self.datetime}\n'
    def update(self, description=None, amount=-1):
        if description!=None:
            self.description = description
        if amount != -1:
            self.amount = amount

    def delete():
        pass    

class ExpenseManager:
    def list():
        pass
    pass

class Category:
    def __init__(self, name="unknown", limit=0):
        self.name = name
        self.limit= limit
