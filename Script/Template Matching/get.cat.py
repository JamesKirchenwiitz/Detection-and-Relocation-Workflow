#!/software/python/anaconda3/bin/python3

################################################
# Loading in Libraries
################################################

import obspy
import obsplus
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from obspy.clients.fdsn import Client
from obspy import UTCDateTime
import datetime
import calendar
import datetime as dt


################################################
# Reading in events
################################################

# Specify client you want to pull data from
client = Client("USGS") 

# specify variable of catalog search
print("Example start date Format: 2020-01-01T00:00:00")
starttime = UTCDateTime(input("Start Date: "))
print("")
print("Example end date Formate: 2025-02-02T00:00:00")
endtime = UTCDateTime(input("End Date: "))
print()
print("Example min latitude: 29.02")
minlatitude=float(input("Area Minimum Latitude: "))
print()
print("Example max latitude: 29.15")
maxlatitude=float(input("Area Maximum Latitude: "))
print()
print("Example min longitude: -97.93")
minlongitude=float(input("Area minimum longitude: "))
print()
print("Example max longitude: -97.75")
maxlongitude=float(input("Area maximum longitude: "))
print()
print("Example min magnitude: 0")
minmagnitude=float(input("Lowest desired magnitude: "))
print()
print("Example output filename: getcatpy.karnescluster2.csv")
output=input("Desired saved filename: ")

# Box search (2020 M4.0 Event Search)
events = client.get_events(starttime=starttime, endtime=endtime, minlatitude=minlatitude, maxlatitude=maxlatitude, minlongitude=minlongitude, maxlongitude=maxlongitude, minmagnitude=minmagnitude)

# Radius search
#events = client.get_events(starttime=starttime, endtime=endtime, latitude=28.939, longitude=-98.037,
#maxradius = 0.09, minmagnitude = 2)

################################################
# Creating localized catalog
################################################

# Creating dataframe
df = obsplus.events_to_df(events)

# making df match hpc command

# changing column names to match
df = df.rename(columns = {'time' : 'decyear', 'latitude' : 'lat',
                          'longitude' : 'lon', 'depth' : 'dep', 'magnitude' : 'mag'})

# converting to epoch time
df['epoch'] = [d.timestamp() for d in df['decyear']]
df['epoch'] = [int(d) for d in df['epoch']]

# setting baseline epoch time at 2020 like hpc command
et = dt.datetime(2020, 1, 1).timestamp()
et = int(et)

# creating decyear column exactly like the hpc command
df['decyear'] = [((d - et)/86400/365.25 + 2020) for d in df['epoch']]


# rounding decyear, epoch, lat, & lon columns to match jan2023.csv
df['decyear'] = df['decyear'].round(7)
df['lat'] = df['lat'].round(4)
df['lon'] = df['lon'].round(4)
df['dep'] = df['dep'] / 1000
df['dep'] = df['dep'].round(3)

# narrowing columns for manipulations sake
df = df[['epoch', 'decyear', 'lat', 'lon', 'dep', 'mag']]

# Turning dataframe into csv file
df.to_csv(output, index = False)
print(len(df))
print('Done')
