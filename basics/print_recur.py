
def recur_print(str_val):
    if len(str_val)> 1000:
        print('limit reached')
        return 
    else: 
        str_val += "hello"
        print(str_val)
        recur_print(str_val) 

str_val = "hi"
recur_print(str_val)