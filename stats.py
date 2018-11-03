## Imports
import pandas as pd
from pyramid.arima import auto_arima as auto


## To perform in-sample forecasting.
def in_sample(marks, data, stats='SARIMA'):
    
    data.dropna(inplace=True)
    
    training = data.iloc[marks[0] : marks[1], 1]
    testing = data.iloc[marks[1] : marks[2], 1]
        
    nahead = marks[2] - marks[1]
    
    
    ## Fitting and forecasting procedures
    if stats=='SARIMA':
        stepwise_model = auto(training, start_p=1, start_q=1,
                           max_p=3, max_q=3, m=12,
                           start_P=0, seasonal=True,
                           D=1, trace=True)
        
        forecast, conf_int = stepwise_model.predict(n_periods=nahead, return_conf_int=True)
        
    full_forecast = pd.Series(data=forecast, index=testing.index)
    
    return [full_forecast, conf_int]


## To perform out-of-sample forecasting.
def out_sample(marks, nahead, data, stats='SARIMA', frequency='D'):
        
    data.dropna(inplace=True)
    
    training = data.iloc[marks[0] : marks[1], 1]

    
    
    ## Fitting and forecasting procedures
    if stats=='SARIMA':
        stepwise_model = auto(training, start_p=1, start_q=1,
                           max_p=3, max_q=3, m=12,
                           start_P=0, seasonal=True,
                           D=1, trace=True)
        
        forecast, conf_int = stepwise_model.predict(n_periods=nahead, return_conf_int=True)
        
        
    ## To extend datetimeindex to create range for forecasting
    new_dates = pd.date_range(str(data.index.date[marks[1]-1]), periods=nahead+1, freq=frequency)
    new_dates = new_dates[1:]
    
    all_dates = list(data.index) + list(new_dates)
    all_dates = pd.DatetimeIndex(all_dates)

    full_forecast = pd.Series(data=forecast, index=new_dates)
    
    
    return [full_forecast, all_dates, conf_int]