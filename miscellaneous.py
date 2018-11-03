## Imports
import datetime as dt

## For the rangeslider beneath code.
def getMarks(dates, all_dates=False):

    dates = list(dates)
    
    date_set = [dates[0] + dt.timedelta(x) for x in range((dates[-1] - dates[0]).days + 1)] 
    missing_index = [0 for i in range(len(date_set))]
    
    for i in range(len(date_set)):
        for j in dates:
            if j == date_set[i]:
                missing_index[i] = 1
                break

    available_dates = {}
    
    for i in range(len(missing_index)):
        if missing_index[i] == 1:
            temp = {'label': str(date_set[i].month)}
            available_dates.update({i : temp})
    
    if all_dates==False:
        return [available_dates, len(date_set)]
    else:
        return date_set
    
    
## To color training and forecasting regions.
def liner(x_0, x_1, x_2):
    
    data = [dict(
          fillcolor = "rgba(63, 81, 181, 0.2)", 
          line = {"width": 0}, 
          type = "rect", 
          x0 = str(x_0), 
          x1 = str(x_1), 
          xref = "x", 
          y0 = 0, 
          y1 = 0.95, 
          yref = "paper"            
    ), dict(
          fillcolor = "rgba(200, 81, 141, 0.32)", 
          line = {"width": 0}, 
          type = "rect", 
          x0 = str(x_1), 
          x1 = str(x_2), 
          xref = "x", 
          y0 = 0, 
          y1 = 0.95, 
          yref = "paper"     
    )]
           
    return data