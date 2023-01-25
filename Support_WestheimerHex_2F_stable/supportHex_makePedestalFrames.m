	function pedestalFrames = supportHex_makePedestalFrames(pedestal, video, timing)
     %% pedestal + background frames
       
        quarter = zeros(.5*video.minDim);         
        pedestalFramesCell = cell(1, timing.UniqueSteps);
		
        %actual scrteen dims
        h2 = 0.5*video.height_pix;
		w2 = 0.5*video.width_pix;
        
        %bitmap size
        c0 = floor(.5*video.minDim);
        
        for s = 1:timing.UniqueSteps
            % template
            pedestalHexMap_q4 = supportHex_makeMask_CM(pedestal.centers_pix, pedestal.size_pix(s), ...
                pedestal.nSides, size(quarter), pedestal.mFactor, video.pix2arcmin/60);
            
            % pedestal color
            pedestal_bitvalues_q4 = pedestalHexMap_q4;
            pedestal_bitvalues_q4(pedestal_bitvalues_q4 == 1) = pedestal.abs_luminance_bit;
            
            % background color
            background_bitvalues_q4 = pedestalHexMap_q4;
            background_bitvalues_q4(background_bitvalues_q4 == 0) = pedestal.background_luminance_bit;
            
            % get the whole frame 
            hexPedestalMapStep_full = int16(supportHex_mkWhole(int16(pedestal_bitvalues_q4) + int16(background_bitvalues_q4)));
            
            % cut the frame
            hexPedestalMapStep = hexPedestalMapStep_full(c0 - h2 + 1:c0 + h2, c0 - w2 + 1:c0 + w2);
            pedestalFramesCell{s} = repmat(hexPedestalMapStep, [1 1 timing.nFramesPerStep]);
        end
        pedestalFrames = cell2mat(pedestalFramesCell);
	end
