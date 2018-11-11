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

    
###### Main code ######

app = dash.Dash(dev_tools_hot_reload=True)

app.scripts.config.serve_locally = True

app.config['suppress_callback_exceptions'] = True


## Settings needed to memoize/save data (along with running Redis server)
CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_REDIS_URL': os.environ.get('REDIS_URL', 'localhost:6379')
}
cache = Cache()
cache.init_app(app.server, config=CACHE_CONFIG)



## New way
app.layout = html.Div(children=[
    
    html.Div(children=[
    
                html.Div(children=[
                    html.H1(children='Basic Forecast'),

                    html.Div(children=[
                        html.Label('Input stock ticker:',
                                   style={'margin-right':'10px'}),

                        dcc.Input(id='online_input', value='AMZN', type='text',
                                  style={'width':'1in'}
                                 )],

                             style={'display':'inline-block'}),
                    
                ],
                         
                         style={'display':'inline-block', 'margin-right':'10px'}),
        
        
                html.Div(children=[

                        html.H3('Select date range for data'),

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
             style={'dispaly':'inline-block'}
            ),
    
        html.Button('Search', id='run_search', n_clicks_timestamp='0'),


    
#     html.H3('Select date range for data'),

    
#     dcc.DatePickerRange(
        
#         id='training_range_picker',
#         min_date_allowed = dt.date(1900, 1, 1),
#         max_date_allowed = dt.datetime.today(),

#         ## Default example dates
#         start_date = dt.datetime(2018,3,4),
#         end_date = dt.datetime(2018,6,20)
#     ),
    
    html.Div(),
    
    ## Second set of two columns
    html.Div(children[
        
        html.Div(children[
    
            html.Div(children=[

                html.Label("Statistical Options:",
                           style={'margin-right':'10px'}),

                html.Button('Analyze', id='run_analysis', n_clicks_timestamp='0')],

                     style={'margin-top':'30px','float':'left'}),

            html.Div(children=[dcc.Dropdown(id='stats-function', options=stats_functions)],
                     style={'margin-top':'10px','max-width':'200px'}),

            html.Div(children=[dcc.Dropdown(id='stats-chooser', options=stats_options)],
                     style={'max-width':'200px'}),
        ],

            style={'display':'inline-block'}),
    
         html.Div(children=[],
                  style={'display':'inline-block'})
    ],
             
              style={'display':'inline-block'}),

    
    
 
    
    
#     dcc.DatePickerRange(
        
#         id='training_range_picker',
#         min_date_allowed = dt.date(1900, 1, 1),
#         end_date= dt.datetime.now(),

#         initial_visible_month = dt.datetime.now()),
        
        
#     dcc.DatePickerSingle(
        
#         id='test_date_picker',
#         min_date_allowed = dt.date(1900, 1, 1),
#         date=dt.datetime.now()),
    
    
    html.Div(dcc.Input(id='forecast_range', value='', type='text')),

    html.Div(id='output_graph'),
    
    html.Div(id='range_slider'),
    
    html.Div('range_slider'),
    
    ## Hidden signal value for graph data
    html.Div(id='signal', style={'display': 'none'}),
    
    ## Hidden state value for statistical data
    html.Div(id='stats-data', style={'display': 'none'})
#     dcc.Storageorage(id='stats-data')

])



# app.css.append_css({
#     'external_url': 'https://codepen.io/chriddyp/pen/bWLwgP.css'
# })



if __name__ == '__main__':
    app.run_server(debug=True)
