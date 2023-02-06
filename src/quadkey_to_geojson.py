#!/usr/bin/env python

import sys
from pyquadkey2 import quadkey
from shapely.geometry import Polygon
import pandas as pd
import geopandas as gpd


def tile_polygon(qk):

    try:
        qk = quadkey.QuadKey(str(qk))
    except:
        return None

    a1 = qk.to_geo(anchor = 1)
    a2 = qk.to_geo(anchor = 2)
    a3 = qk.to_geo(anchor = 3)
    a4 = qk.to_geo(anchor = 5)

    bottom_l = [a1[1], a1[0]]
    bottom_r = [a4[1], a4[0]]
    top_l = [a3[1], a3[0]]
    top_r = [a2[1], a2[0]]

    return(Polygon([bottom_l, bottom_r, top_r, top_l]))

def main():

    qks = sys.stdin.read().split("\n")
    
    polygons = [tile_polygon(x) for x in qks]
    
    gdf = pd.DataFrame.from_dict(dict(zip(qks, polygons)),
        orient='index').reset_index()
    
    gdf.columns = ['quadkey','geometry']
    
    gdf = gpd.GeoDataFrame(gdf, crs=4326)

    print(gdf.to_json())

if __name__ == "__main__":
    main()

