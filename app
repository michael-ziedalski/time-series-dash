## Imports
import dash
import dash_core_components as dcc
import dash_html_components as html

from dash.dependencies import Input, Output, State

## For memoization.
from flask_caching import Cache
import os

import datetime as dt
import pandas as pd
import numpy as np

## Quandl, for basic stock data download, with custom api key option coming later.
import quandl as qd
api =  '1uRGReHyAEgwYbzkPyG3'
qd.ApiConfig.api_key = api 



## Imports from folders
from stats import in_sample, out_sample
from miscellaneous import getMarks, liner
from data_input import add_years
 


## Statistical functions available.
stats_functions = [{'label': 'SARIMA', 'value': 'SARIMA'},
                 {'label': 'GARCH', 'value': 'GARCH'}]
## Available ptions for statistical routines (only two for now). 
stats_options = [{'label': 'in-sample', 'value': 'insample'},
                 {'label': 'forecast', 'value': 'forecast'}]  

## Fonts
# Major label fonts
major_fonts = "Arial"
# Minor label fonts
minor_fonts = "lato, Arial"


    
###### Main code ######

app = dash.Dash(dev_tools_hot_reload=True)

app.scripts.config.serve_locally = True

app.config['suppress_callback_exceptions'] = True


## Settings needed to memoize/save data (for now requires running Redis server)
CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_REDIS_URL': os.environ.get('REDIS_URL', 'localhost:6379')
}
cache = Cache()
cache.init_app(app.server, config=CACHE_CONFIG)



## New way
app.layout = html.Div(children=[
    
    ##1st extra-dimensional Div to force 1st set of columns left
    html.Div(children=[
        ## 1st set of two columns
        html.Div(children=[

                    html.Div(children=[
                        html.H1(children='Basic Forecast'),

                        html.Div(children=[
                            html.Label('Input stock ticker:',
                                       style={'margin-right':'10px', 'font':'16px '+major_fonts}),

                            dcc.Input(id='online_input', value='AMZN', type='text',
                                      style={'width':'1in'}
                                     )],

                                 style={'display':'inline-block'}),

                    ],

                             style={'display':'inline-block', 'margin-right':'10px'}),


                    html.Div(children=[

                            html.Div(children=[
                                html.H3('Select date range for data', style={'display':'inline', 'margin-right':'35px'}),
                                html.Button('Search', id='run_search', n_clicks_timestamp='0', style={'display':'inline'})],
                                  ),


                            dcc.DatePickerRange(

                                id='training_range_picker',
                                min_date_allowed = dt.date(1900, 1, 1),
                                max_date_allowed = dt.datetime.today(),

                                ## Default example dates
                                start_date = dt.datetime(2018,3,4),
                                end_date = dt.datetime(2018,6,20)
                            )
                    ],

                            style={'display':'inline-block'})  
        ],
                 style={'ddisplay':'inline-block'}
                )
    ],
             style={'float':'left', 'margin-right':'150px'}), # To push second set of columns right
    

    
    
    ## 2nd extra-dimensional div to push set right
    html.Div(children=[
        ## Second set of two columns
        html.Div(children=[

            html.Div(children=[

                html.Div(children=[

                    html.Label("Statistical Options:",
                               style={'margin-right':'10px', 'font':'bold 16px Arial'}),

                    html.Button('Analyze', id='run_analysis', n_clicks_timestamp='0'),
                
                    dcc.Checklist(
                        options=[
                            {'label': 'keep analyzing', 'value': 1}],
                        values = 0)],
                         
                         ## Button font makes the box gray for some reason, style={'font':'15px Arial'}
                         style={'margin-top':'30px','float':'left'}),


                html.Div(children=[
                    html.Label('Forecasting or in-sample'),
                    dcc.Dropdown(id='stats-chooser', options=stats_options)],
                         style={'margin-top':'75px','max-width':'200px',
                                'margin-right':'20px'}),

                html.Div(children=[
                    html.Label('Statistical analysis:'),
                    dcc.Dropdown(id='stats-function', options=stats_functions)],
                             style={'margin-top':'15px','max-width':'200px',
                                   'margin-right':'20px'}),
            ],

                style={'display':'inline-block'}),

             html.Div(children=[
    #              html.Button('Save graph', id='save_graph', n_clicks_timestamp='0'),
    #              html.Button('Reset', id='reset', n_clicks_timestamp='0'),
                 html.Div(children=[
                     html.Label("Periods to forecast ahead"),
                     html.Div(children=[
                         dcc.Input(id='forecast_range', value='', type='text')],
                                   style={'margin-top':'10px'})]),
                 ],
                      style={'display':'inline-block', 'vertical-align': '300%'})
        ],
                  style={'display':'inline-block', 'font': '16px '+minor_fonts})
        
                         ],
             
             style={}), # I could have a 'float':'right' style here, but that would
                        # put it too far to the right, instead used margins in previous

    


    html.Div(id='output_graph', style={}),
    
    html.Div(id='range_slider', style={}),
    
    html.Div('range_slider'),
    
    ## Hidden signal value for graph data
    html.Div(id='signal', style={'display': 'none'}),
    
    ## Hidden state value for statistical data
#     html.Div(id='stats-data', style={'display': 'none'})
    dcc.Store(id='stats-data')

])



@cache.memoize()
def get_data(data_input, start_train_date, end_train_date):
            
        ## All date stuff
        start_date = dt.datetime.strptime(start_train_date, '%Y-%m-%d') #for more options %H:%M:%S.%f
        dt_start_date = dt.datetime.strftime(start_date,'%Y-%m-%d')
        end_date = dt.datetime.strptime(end_train_date, '%Y-%m-%d') 
        dt_end_date = dt.datetime.strftime(end_date,'%Y-%m-%d')
        
        data = qd.get_table('WIKI/PRICES', qopts={'columns': ['ticker', 'date', 'close']},
                        ticker=[data_input], date={'gte': str(start_date), 'lte': str(end_date)})

        data.reset_index(inplace=True, drop=True)
        data.set_index('date', inplace=True)
        name = data_input
        
        ## Quandl date error-handling
        if (data.index[-1] != start_date) or (data.index[0] != end_date):
            return [data.to_json(), str(dt_end_date)]
        else:
            return [data.to_json(), name]

    
    
@app.callback(Output('signal', 'children'),
             [Input('run_search', 'n_clicks_timestamp')],
             [State(component_id='online_input', component_property='value'),

             State(component_id='training_range_picker', component_property='start_date'),
             State(component_id='training_range_picker', component_property='end_date')])
def compute_value(run, online_input, start_train_date, end_train_date):
    return get_data(online_input, start_train_date, end_train_date)
    
    
@app.callback(
    Output(component_id='output_graph', component_property='children'),
    [Input(component_id='signal', component_property='children'),
     Input(component_id='year_slider', component_property='value'),
     Input(component_id='stats-data', component_property='data')]   
)
def create_graph(plot_data, slider_dates, stats_data):

    if plot_data[0] is None:
                
        end = dt.datetime.now()
        start = add_years(end, -3)

        datedelta = pd.date_range(start=start, end=end)
        datedelta = datedelta.strftime('%y-%m-%d')
        datedelta = list(datedelta)
        zeros = [0 for i in range(len(datedelta))]
        
        if type(plot_data[0]) is str:
            name = plot_data[0]
        else:
            name = ""

        return dcc.Graph(
            id='empty_graph',
            figure={
                'data': [
                    {'x': datedelta, 'y': zeros, 'type': 'line', 'name': name}
                ],
                'layout': {
                    'title': name
                }
            }
        )
    

    elif (plot_data[0]) and (slider_dates is None):
        
        return html.Div('There is no slider info')
    

        data = pd.read_json(plot_data[0])
        name = plot_data[1]
                
        
        return dcc.Graph(
            id='time-series_graph',
            figure={
                'data': [
                    {'x': data.index, 'y': data.close, 'type': 'line', 'name': name}
                ],
                'layout': {
                    'title': name#, 'sliders' : sliders
                }
            }
        )
    

    elif plot_data[0] and slider_dates and not stats_data:
        
            
        data = pd.read_json(plot_data[0])
        name = plot_data[1]
        
        date_set = getMarks(data.index.date, all_dates=True)
        shape_info = liner(date_set[slider_dates[0]], date_set[slider_dates[1]], date_set[slider_dates[2]])

        
        return dcc.Graph(
            id='time-series_graph',
            figure={
                'data': [
                    {'x': data.index, 'y': data.close, 'type': 'line', 'name': name}
                ],
                
                'layout': 
                    {'title': name, 'shapes': shape_info}      
                }
            )
        
        
        
    elif plot_data[0] and slider_dates and stats_data:
        
        
        data = pd.read_json(plot_data[0])
        name = plot_data[1]
        
        if stats_data[1] == 0:
            
            date_set = getMarks(data.index.date, all_dates=True)
            shape_info = liner(date_set[slider_dates[0]], date_set[slider_dates[1]], date_set[slider_dates[2]])

            full_forecast, conf_int = in_sample([slider_dates[0], slider_dates[1], slider_dates[2]], data) 
        
        elif stats_data[1] == 1:
            
            ## Minor error catch
            if not stats_data[2]:
                return html.Div('No forecast range inputted.')
            
            full_forecast, all_dates, conf_int = out_sample([slider_dates[0], slider_dates[1]], stats_data[2], data) 
                    
            date_set = getMarks(all_dates.date, all_dates=True)
            shape_info = liner(date_set[slider_dates[0]], date_set[slider_dates[1]], date_set[-1])
            
        
                
        return dcc.Graph(
            id='time-series_graph',
            figure={
                'data': [  
                    {'x': data.index, 'y': data.close, 'type': 'line', 'name': name}, # Curent best attempt at fixing dynamic range of xaxis: 'xaxis': {'range': [str(data.index[0]), str(data.index[-1]]}}
                    ## These three below are to graph statistical results.
                    {'x': full_forecast.index, 'y': full_forecast.values, 'type': 'line', 'name': name},
                    {'x': full_forecast.index, 'y': conf_int[:,1], 'type': 'line', 'name': name},
                    {'x': full_forecast.index, 'y': conf_int[:,0], 'type': 'line', 'name': name}
                ],
                
                'layout': 
                    {'title': name, 'shapes': shape_info}      
                }
            )
    
    
    
    
## To 'close the valve' afterward, to stop displaying the stats-data
## if A) the rangeslider changes, or B) the data itself changes.
## What's fucked up is this does not work if it is placed after 'create_rangeslider', 
## because it references 'year_slider', which does not exist on the list of rendered components, but placing 
## this callback before makes it work, which I intuited was how 'create_graph' was getting along.
@app.callback(
    Output(component_id='stats-data', component_property='clear_data'),
    [Input(component_id='year_slider', component_property='value'),
     Input(component_id='signal', component_property='children')]
)
def rest_stats_choice(year_slider, time_series):
        return True
        
        
        

## Second input, stats-data, beginning setup for trying to update rangeslider
## for forecasting procedure, but unsure why or how to implement this yet.
@app.callback(
    Output(component_id='range_slider', component_property='children'),
    [Input(component_id='signal', component_property='children')]
)
def create_rangeslider(plot_data):

    if plot_data[0] is None:
        
        return  html.Div("testing")
    
        return html.Div(children=
            dcc.RangeSlider(
                id='blank_slider',
                disabled=True),
                    
            ## To line up slider underneath graph.
            style = {'width' : '89%', 'margin-left' : 'auto', 'margin-right' : 'auto'}       
        )
        
        
    elif plot_data[0]:
                        
        data = pd.read_json(plot_data[0])
        name = plot_data[1]
                
        ## For the slider.
        marks_var, length = getMarks(data.index.date)
            
        return html.Div(children=
                dcc.RangeSlider(
                    id='year_slider',
                    min = 0,
                    max = length-1,
                    value = [0, int(length/2), length-1], # Good starting values.
                    marks = marks_var,
                    
                    step = None,
                ),

                ## To line up slider.
                style = {'width' : '89%', 'margin-left' : 'auto', 'margin-right' : 'auto'}       
            )
        
        
        

## To 'open the valve', on running a statistical routine, with a button.
@app.callback(
    Output(component_id='stats-data', component_property='data'),
    [Input(component_id='run_analysis', component_property='n_clicks_timestamp')],
    [State(component_id='stats-function', component_property='value'),
     State(component_id='stats-chooser', component_property='value'),
     State(component_id='forecast_range', component_property='value')]
)
def store_stats_data(run, stats_function, insample_or_forecast, forecast_range):  

     ## After either button has been pressed.
    if insample_or_forecast == 'insample':
        return [stats_function, 0]
    elif insample_or_forecast == 'forecast':
        ## If forecasting is chosen, the forecast_range will be 
        ## necessary, and better to put it here than in create_graph
        return [stats_function, 1, int(forecast_range)]

    
if __name__ == '__main__':
    app.run_server(debug=True)

