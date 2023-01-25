function [timingSeq, framesSeq] = westheimerHex_2F_stable(parameters_stimulus, parameters_video, parameters_timing)

    %% Part 1. Conversion
        switch parameters_stimulus.viewMode
            case 'Square'
                parameters_video.minDim = min(parameters_video.width_pix, parameters_video.height_pix);
            case 'Fullscreen'
                parameters_video.minDim = max(parameters_video.width_pix, parameters_video.height_pix);
            otherwise
            % default to square
                parameters_video.minDim = min(parameters_video.width_pix, parameters_video.height_pix);    
        end
        
        % cm to degs
        parameters_video.width_deg = 2 * atand( (parameters_video.width_cm/2)/parameters_video.viewDistCm);
        parameters_video.height_deg = 2 * atand( (parameters_video.height_cm/2)/parameters_video.viewDistCm );
        parameters_video.pix2arcmin = ( parameters_video.width_deg * 60 ) / parameters_video.width_pix;

        % convert arcmins, % to pixel values
        
        base.size_pix = floor(parameters_stimulus.baseSize_amin/parameters_video.pix2arcmin);
        pedestal.size_pix = floor(parameters_stimulus.pedestalSize_pct*base.size_pix/100);
        probe.size_pix = floor(parameters_stimulus.probeSize_pct*base.size_pix/100);
        
        % display luminance to bitmap object      
        display_lutObj = xdc_LinearGammaTable(parameters_video.minLuminanceCd, parameters_video.maxLuminanceCd);
        %actualMeanLuminance = display_lutObj.
                
        base.abs_luminance_cd = parameters_stimulus.bgrLum_cd;
        pedestal.abs_luminance_cd = parameters_stimulus.pedestalLum_cd;        
        probe.rel_luminance_cd = parameters_stimulus.pedestalLum_cd.*(parameters_stimulus.probeLum_pct/100);

        % convert to byte
        base.abs_luminance_bit = display_lutObj.byteValueForLuminance(base.abs_luminance_cd);
        pedestal.abs_luminance_bit = display_lutObj.byteValueForLuminance(pedestal.abs_luminance_cd);
        %probe.rel_luminance_bit = display_lutObj.byteValueForLuminance(probe.rel_luminance_cad);
        
        
        pedestal.background_luminance_bit = base.abs_luminance_bit;
        
        % calculate distance from pedestal in % contrast for each value in parameters_stimulus.probeLum_pct
        
        [~, maxByteVal_Contrast, ~] = arrayfun( @(x) display_lutObj.byteValuesForContrast(...
            x, pedestal.abs_luminance_cd), parameters_stimulus.probeLum_pct);
        
        probe.rel_luminance_bit = abs(maxByteVal_Contrast - pedestal.abs_luminance_bit);
                  
        % copy magFactor 
        base.mFactor = parameters_stimulus.mfactor;
        pedestal.mFactor = parameters_stimulus.mfactor;
        probe.mFactor = parameters_stimulus.mfactor;
        
        % generate centers (basing on base hex size  for spacing)
        hexcenters_pix = supportHex_getHexCenters(base, parameters_video.minDim, parameters_video.pix2arcmin);
        
        % copy centers to probe/pedestal   
        pedestal.centers_pix = hexcenters_pix;
        probe.centers_pix = hexcenters_pix;
        
        % init nSides for pedestal, probe (hexagon)
        pedestal.nSides = 6;        
        probe.nSides = 6;
        
        % copy activation pattern to probe
        probe.up_down = parameters_stimulus.probeHF;
        probe.left_right = parameters_stimulus.probeHS;        
        probe.contrast_direction = parameters_stimulus.probeDirectionChange;
        probe.fov_per = parameters_stimulus.probeFovPer;
        probe.modulation = parameters_stimulus.modType;
        
        % timing
        parameters_timing.nFramesPerStep = nUniqueFramesPerStep(parameters_stimulus, parameters_timing);
        parameters_timing.UniqueSteps = parameters_timing.nCoreSteps;
        if (strcmp(parameters_stimulus.sweepType, 'Fixed'))
            parameters_timing.UniqueSteps = 1;
        end
        parameters_timing.nUniqueFrames = parameters_timing.UniqueSteps*parameters_timing.nFramesPerStep;
        
        % pedestal frames are static  
        pedestalFrames = supportHex_makePedestalFrames(pedestal, parameters_video, parameters_timing);
        %f1
        probeFrames_1 = supportHex_createProbeFrames(probe, 1, parameters_video, parameters_timing);       
        %f2
        probeFrames_2 = supportHex_createProbeFrames(probe, 2, parameters_video, parameters_timing);
        % sum it up
        framesSeq(:, :, 1, :) = uint8(pedestalFrames + probeFrames_1 + probeFrames_2);

        %% make imageSequence
        imSeq = [];
        updateEveryFrame = parameters_timing.nFramesPerStep;
        totalRepeats = parameters_timing.framesPerStep/updateEveryFrame;
        uniqueSteps = linspace(1, parameters_timing.UniqueSteps, parameters_timing.nCoreSteps);
        
        for s = 1:parameters_timing.nCoreSteps
            stepFrames = (1 + parameters_timing.nFramesPerStep*(uniqueSteps(s) - 1):uniqueSteps(s)*parameters_timing.nFramesPerStep)';
            imSeq = cat(1, imSeq, repmat(stepFrames, [totalRepeats 1]));
        end
		preludeSeq = [];
		postludeSeq = [];
		if (parameters_timing.nPreludeBins)
			% repeat first step and last step
			preludeSeq = imSeq(1:parameters_timing.nPreludeFrames);
			postludeSeq = imSeq(end - parameters_timing.nPreludeFrames + 1:end);
		end
		
        timingSeq = [preludeSeq; uint32(imSeq); postludeSeq];
    end
        %% Timing frames   
    
    function nf = nUniqueFramesPerStep(stimset, timing)
        switch(stimset.modType)
            case 'None'
                nf = lcm(timing.updateFramesPerCycle(1), timing.updateFramesPerCycle(2));
            case 'Square'
                nf = lcm(timing.updateFramesPerCycle(1), timing.updateFramesPerCycle(2));
            case {'Sawtooth-on', 'Sawtooth-off'}
                nf = lcm(timing.updateFramesPerCycle(1), timing.updateFramesPerCycle(2));
        end
        
    end
 