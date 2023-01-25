	function probeFrames = supportHex_createProbeFrames(probesData, nFrequency, video, timing)
    
        % use 4th quadrant for probe map
        quarter = zeros(.5*video.minDim); 
        %activationTable = probeLookupTable(size(stimset.hexCenters, 1), stimset.probeTable{nF}); 
        

        % AY added fix for Left-Right paradigm removing the element om (0,
        % Y) axis
        activeCenters = getProbeActivationTable(probesData.centers_pix, probesData.mFactor, ...
            video.pix2arcmin/60, probesData.fov_per{nFrequency}, probesData.left_right{nFrequency});
        
        % taking out unused probes
        probeCenters = probesData.centers_pix((activeCenters > 0), :);
        
        
        probeHexMap_q4 = supportHex_makeMask_CM(probeCenters, probesData.size_pix(nFrequency), ...
            probesData.nSides, size(quarter), probesData.mFactor, video.pix2arcmin/60);            
        
        
        hexProbeMap = supportHex_mkWhole(probeHexMap_q4);              
        sfMask = applySubfieldMask(hexProbeMap, probesData.up_down{nFrequency}, probesData.left_right{nFrequency}); 
%% Commented on 1/23, introduces probe location shift        
%         %workaround to remove center flickering element
%         probeHexMap_fov = supportHex_makeMask_CM(probesData.centers_pix(2, :), probesData.size_pix(nFrequency), ...
%             probesData.nSides, size(quarter), probesData.mFactor, video.pix2arcmin/60);
%         
%         [x, ~] = find(probeHexMap_fov == 1);
%         
%         medProbeH = max(x) + 1;
%         sfMask(size(quarter, 1) + 1:size(quarter, 1) + medProbeH, :) = 1;
%% endof Commented on 1/23
    hexProbeMap_full = int16(hexProbeMap.*sfMask);
        
        % cut the frame to resolution
        h2 = 0.5*video.height_pix;
		w2 = 0.5*video.width_pix;
        
        % static bitmaps
        c0 = floor(.5*video.minDim);
        hexProbeMap = hexProbeMap_full(c0 - h2 + 1:c0 + h2, c0 - w2 + 1:c0 + w2);
        
        % contrast change   
        sweepModProfile = supportHex_getProbeModProfile(timing.updateFramesPerCycle(nFrequency), ...
            probesData.modulation, probesData.contrast_direction);               
        
        
        hexProbeFrames = repmat(hexProbeMap, [1 1 timing.updateFramesPerCycle(nFrequency)]);
        
        probeFramesCell = cell(1, timing.UniqueSteps);
        for s = 1:timing.UniqueSteps
            probeLuminanceStep = int16(sweepModProfile*double(probesData.rel_luminance_bit(s, nFrequency)));            
            probeFramesStep = bsxfun(@times, hexProbeFrames,...
                reshape(probeLuminanceStep, 1, 1, numel(probeLuminanceStep)));
            probeFramesCell{s} = probeFramesStep;
        end
        
        probeFrames =  int16(repmat(cell2mat(probeFramesCell), [1  1 timing.nUniqueFrames/timing.updateFramesPerCycle(nFrequency)]));            
    end
    
    
%     %% Sector map 
%     function probeTable = probeLookupTable(nCenters, sector)
%         
%         nSectors = 3;
%         % remove the center element
%         sectorWidth = round((nCenters - 1)/nSectors);
%         sectorOverlap = 1;
%         probeTable = zeros(nCenters, 1);
%         switch sector
%             case 'f1'                
%                 fStart = 1;
%                 fEnd = sectorWidth + sectorOverlap + 1;
%             case 'p1'
%                 % extra 1 for the center probe (first in the map)
%                 fStart = 1 + sectorWidth + sectorOverlap;
%                 fEnd = fStart + sectorWidth;
%             case 'p2'
%                  % extra 1 for the center probe (first in the map)               
%                 fStart = 1 + 1 + 1 + 2*sectorWidth - sectorOverlap;
%                 fEnd = nCenters;
%             case 'fov'
%                 fStart = 1;
%                 fEnd = sectorWidth;               
%             case 'per'
%                 fStart = 1 + sectorWidth;
%                 fEnd = nCenters;               
%             case 'All'
%                 fStart = 2;
%                 fEnd = nCenters;
%         end
%         probeTable(fStart:fEnd) = 1;
%     end
%     
    %% degree map
    
    function activeCenters = getProbeActivationTable(hexCenters, mfactor, pix2deg, activeRegion, isLR)
     % after magnification
        centersMagnified = supportHex_getHexCentersMagnified(hexCenters, mfactor, pix2deg);
        foveaSizeDeg = 5;
        foveaSizePx = foveaSizeDeg/pix2deg;
        foveaSizePx_CutOff = 0.5*foveaSizePx;
        
        switch activeRegion
            case 'Fov'
                activeCenters = (centersMagnified(:, 1) < foveaSizePx_CutOff).* ...
                    (centersMagnified(:, 2)<foveaSizePx_CutOff);
            case 'Per'
                activeCenters = ~((centersMagnified(:, 1) < foveaSizePx_CutOff).* ...
                    (centersMagnified(:, 2)<foveaSizePx_CutOff));
            case 'All'
                activeCenters = ones(size(centersMagnified, 1), 1);
                % disable center element probe
                activeCenters(1, 1) = 0;
            otherwise
        end
        %removing additional element on Y axis
        switch isLR
            case {'Left', 'Right'}
                activeCenters(2, 1) = 0;
            otherwise
                %do nothing
        end
    end

    function out = applySubfieldMask(frame, InfSup, TempNas)
    
        quarterMask = ones(0.5*size(frame));
        is = zeros(2, 2);
        tn = zeros(2, 2);
        switch InfSup
            case 'Upper'
                is(1, :) = 1;
            case 'Lower'
                is(2, :) = 1;
            case 'All'
                is(:, :) = 1;
        end
    
        switch TempNas
            case 'Left'
                tn(:, 1) = 1;
            case 'Right'
                tn(:, 2) = 1;
            case 'All'
                tn(:,:) = 1;  
        end
        
        q = is.*tn;
        out = [q(1, 1)*quarterMask, q(1, 2)*quarterMask; q(2, 1)*quarterMask, q(2, 2)*quarterMask];
    end    
