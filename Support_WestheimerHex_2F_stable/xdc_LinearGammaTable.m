% 2022 Vladimir Vildavski, Stanford University
% xdc_LinearGammaTable class definition
% Dependencies: none

classdef	xdc_LinearGammaTable < handle
	properties
		minLum;			% minimum luminance in Cd/m^2
		lumRange;		% luminance range in Cd/m^2
	end	% properties

	methods
		function	obj = xdc_LinearGammaTable( varargin)
			if nargin == 2
				[ minLumCd, maxLumCd] = deal( varargin{1:2});
				obj.init( minLumCd, maxLumCd);
			end
		end

		function	init( obj, minLumCd, maxLumCd)
			obj.minLum		= minLumCd;
			obj.lumRange	= maxLumCd - minLumCd;
		end

		function	luminance = maxLuminance( obj)
			luminance	= obj.minLum + obj.lumRange;
		end
		
		function	luminance = minLuminance( obj)
			luminance	= obj.minLum;
		end
		
		function	byteValue = byteValueForLuminance( obj, luminance)
			% (1) convert from luminance to normalized [0-1] color
			% (2) return nearest uint8 value [0-255] for this color,
			% which is the same as obj.byteValueForColorValue(normColor)
			normColor	= ( luminance - obj.minLum) / obj.lumRange;		% (1)
			byteValue	= uint8( round( normColor * 255.0));			% (2)
		end

		function	luminance = luminanceForByteValue( obj, byteValue)
			% (1) convert from byteValue [0-255] to normalized [0-1] color
			% (2) convert from normalized color to luminance
			normColor	= obj.colorValueForByteValue( byteValue);		% (1)
			luminance	= obj.minLum + normColor * obj.lumRange;		% (2)
		end

		function	colorValue = colorValueForLuminance( obj, luminance)
			% (1) convert from luminance to normalized [0-1] color
			% (2) get nearest uint8 value [0-255] for this color
			% (3) return achievable color value, same as obj.colorValueForByteValue()
			% (1,2) is the same as obj.byteValueForLuminance(obj,luminance)
			normColor	= ( luminance - obj.minLum) / obj.lumRange;		% (1)
			byteValue	= uint8( round( normColor * 255.0));			% (2)
			colorValue	= double( byteValue) / 255.0;					% (3)
		end

		function	luminance = luminanceForColorValue( obj, colorValue)
			% This function guarantees the actual luminance value by
			% (1,2) converting back and forth between color and byte
			% values, so the resulting 'colorVal' corresponds to one of
			% discrete byte values.
			% (3) convert from normalized [0-1] color to luminance
			byteValue	= obj.byteValueForColorValue( colorValue);		% (1)
			colorValue	= obj.colorValueForByteValue( byteValue);		% (2)
			luminance	= obj.minLum + colorValue * obj.lumRange;		% (3)
		end

		function	luminance	= actualLuminance( obj, luminance)
			byteValue	= obj.byteValueForLuminance( luminance);
			luminance	= obj.luminanceForByteValue( byteValue);
		end

		function	[ darkByteValue, brightByteValue, actualContrast] = ...
					byteValuesForContrast( obj, contrastPct, meanLuminance)
			%
			%	
			contrast01	= double( contrastPct) / 100.0;
			meanColor	= obj.colorValueForLuminance( meanLuminance);
			colorDelta	= contrast01 * ( meanColor + obj.minLum / obj.lumRange);
			darkColor	= meanColor - colorDelta;
			brightColor	= meanColor + colorDelta;

			darkByteValue	= obj.byteValueForColorValue( darkColor);
			brightByteValue	= obj.byteValueForColorValue( brightColor);

			actualMeanLum	= obj.luminanceForColorValue( meanColor);
			actualBrightLum	= obj.luminanceForByteValue( brightByteValue);
			actualContrast	= 100.0 * ( actualBrightLum - actualMeanLum) / actualMeanLum;

		end
		
		function	maxContrast = maxBrightContrast( obj, meanLuminance)
			% c = (maxLum - meanLum)/meanLum = maxLum/meanLum - 1
			actualMeanLum	= obj.actualLuminance( meanLuminance);
			maxContrast		= 100.0 * ( obj.maxLuminance() / actualMeanLum - 1.0);
		end
		
		function	maxContrast = maxDarkContrast( obj, meanLuminance)
			% c = (meanLum - minLum)/meanLum = 1 - minLum/meanLum
			actualMeanLum	= obj.actualLuminance( meanLuminance);
			maxContrast		= 100.0 * ( 1.0 - obj.minLuminance() / actualMeanLum);
		end
		
		function	minContrast = minContrast( obj, meanLuminance)
			% Minimum contrast is the same for the bright and dark pixels
			% (1) get byte value corresponding to meanLuminance
			% (2) get luminance of this byte value incremented by one
			% (3) get actual achievable mean luminance
			% (4) c = (brightLum - meanLum)/meanLum = brightLum/meanLum - 1
			meanLumByteVal	= obj.byteValueForLuminance( meanLuminance);		% (1)
			brightLum		= obj.luminanceForByteValue( meanLumByteVal + 1);	% (2)
			actualMeanLum	= obj.actualLuminance( meanLuminance);				% (3)
			minContrast		= 100.0 * ( brightLum / actualMeanLum - 1.0);		% (4)
		end
		
	end	% methods (public)

	methods ( Access = 'private')

	end	% methods	( Private)

	methods ( Static = true)

		function	byteValue = defaultMeanLuminanceByteValue
			byteValue	= uint8(128);	% By convention, it's 128.
		end

		function	byteValue = byteValueForColorValue( normColor)
			% return nearest uint8 value [0, 255] for the normalized [0-1] color
			byteValue	= uint8( round( normColor * 255.0));
		end

		function	colorValue = colorValueForByteValue( byteValue)
			% convert uint8 value [0-255] to normalized [0-1] color
			colorValue	= double( byteValue) / 255.0;
		end

	end	% methods (Static)

end	% classdef
