#!/usr/bin/env python3
import sys

'''
This method will sort a CSV genrated from a raster of 3 values (x,y,probability)
output is in an image-like csv (y increases from top to bottom, x increases from left to right) keeping only probability
The idea is that if all our models use the same cropped lat and long we can be consistent in the model output, and our comparator can easily compare the same coordinates of each model
'''
def main():
	inFile = sys.argv[1]
	rasterPoints = {}
	with open(inFile) as file:
		for i, line in enumerate(file):
			vals = line.strip().split(',')
			if vals[1] in rasterPoints:
				rasterPoints[vals[1]].append({
					'x' : vals[0],
					'prob' : vals[2]
				})
			else:
				rasterPoints[vals[1]] = []
				rasterPoints[vals[1]].append({
					'x' : vals[0],
					'prob' : vals[2]
				})
	for y in sorted(rasterPoints):
		firstItr = True
		for x in sorted(rasterPoints[y], key=lambda x: x['x']):
			#print('y: {}, x: {}'.format(y, x['x']))
			if firstItr:
				print(x['prob'], end='')
				firstItr = False
			else:
				print(', {}'.format(x['prob']), end='')
		print('\n', end='')
			
if __name__ == '__main__':
    main()