## Imports

import datetime as dt
# import quandl as qd


# ## Quandl, for basic stock data download, with custom api key option coming later.

# api =  '1uRGReHyAEgwYbzkPyG3'
# qd.ApiConfig.api_key = api 



# ## Main function to download data from quandl
# def quandl_data(start_date, end_date, online_input):

#     start_date = dt.datetime.strptime(start_train_date, '%Y-%d-%m')
#     end_date = dt.datetime.strptime(end_train_date, '%Y-%m-%d') 
#     end_date = end_date.strftime('%Y-%d-%m')

#     data = qd.get_table('WIKI/PRICES', qopts={'columns': ['ticker', 'date', 'close']},
#                     ticker=[online_input], date={'gte': str(start_date), 'lte': str(end_date)})

#     data.reset_index(inplace=True, drop=True)
#     data.set_index('date', inplace=True)

#     return data
    
    
## To be able to add 'x years' to a given date, only used=
## to generate empty graph based on relatively current dates
def add_years(d, years):
    """Return a date that's 'years' years after the date (or datetime)
    object 'd'. Return the same calendar date (month and day) in the
    destination year, if it exists, otherwise use the following day
    (thus changing February 29 to March 1).

    """
    try:
        return d.replace(year = d.year + years)
    except ValueError:
        return d + (dt.date(d.year + years, 1, 1) - dt.date(d.year, 1, 1))
    
    
