# -*- coding: utf-8 -*-
"""
Created on Mon Mar  9 15:13:34 2020

@author: Conor.Frailey
"""

import dash
import dash_core_components as dcc
import dash_html_components as html
import pandas as pd
import pyodbc
import sqlalchemy as sa
import urllib
import mysql.connector

params = urllib.parse.quote_plus("DRIVER={SQL Server Native Client 11.0};"
                                 "SERVER=iceman;"
                                 "DATABASE=SysproReporting;"
                                 "Trusted_Connection=yes")

engine = sa.create_engine('mssql+pyodbc:///?odbc_connect={}'.format(params))

hmmmmm = pd.read_sql_query('''
                           select count(1) as hello,
                               'hi' as name
                            from SysproReporting.dbo.SorMaster
                           ''',
                     con = engine
                     )



external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']


cnx = mysql.connector.connect(user='Reports',
                              password='Build$om3thing',
                              host='starfire',
                              database='buildsomething')

hmmmmmy = pd.read_sql_query('''
                           select count(1) as hello,
                               'hi' as name
                            from tbladdress
                           ''',
                     con = cnx
                     )

cnx.close()