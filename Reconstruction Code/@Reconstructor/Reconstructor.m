%Should have input grainmap, and output grainmap

classdef Reconstructor < handle
    
    properties
        
        grainmap@Grainmap
        daughterGrains
        triplets
        trios
        clusters
        filteredClusters
        alternateOrientationClusters
        misotolerance

        clusterIDmat
        
        reconstructedIPFmap

        %Reconstruction options
        OR
        phasekey %Include types of crystal symmetry present in each phase?
        reconstructionPhases
        tripletMinNeighborMiso = 5*pi/180;
        trioCutoffMiso = 4*pi/180;
        
        %%%Cleanup options
          %Cluster placement options
        minInteriorOverlapRatio = .9;
        minRedundantOverlapRatio = .5;
        redundantClusterMiso = 10*pi/180;
        
          %SA algorithm options
        numTemps = 70;
        numTrials = 70;
        startAcceptP = .95;
        endAcceptP = .001;

    end
    
    methods
        
        %Constructor
        function obj = Reconstructor(grainmap,OR,reconstructionPhases) %This will be updated to set options via GUI input
            
            %manually set by input options for now:
            if nargin >0
                
                obj.grainmap = grainmap;
                    
                if nargin==3
                    
                    obj.OR = OR;
                    obj.phasekey = grainmap.phasekey;
                    
                    if any(~ismember(reconstructionPhases,grainmap.phasekey.phaseID))
                        error('Given ID numbers for phases to reconstruct contain phase IDs not present in dataset'); 
                    end
                    
                    obj.reconstructionPhases = reconstructionPhases;

                    %Calculate possible parents for each grain to reconstruct
                    %Filter grains that are not a phase to be reconstructed

                    daughterGrainsHold = Grain.empty;
                    for i=1:length(grainmap.grains)
                        currGrain = grainmap.grains(i);
                        phaseID = currGrain.phaseID;
                        if ~isempty(phaseID) && ismember(phaseID,reconstructionPhases)
                            currGrain.set_transformationPhase(OR,'daughter');
                            daughterGrainsHold = [daughterGrainsHold currGrain];
                        end
                    end

                    obj.daughterGrains = daughterGrainsHold;
                
                end
                
            end
                
        end
        
        %Define triplets
        find_triplets(obj,selectedSet)
        
        %Call each triplet's calc_trios function
        find_trios(obj)
        
        %Grow clusters from every trio found
        grow_clusters_from_trios(obj)
        
        gen_cluster_IDmat(obj)
        
        %Place clusters, divide ARs
        place_clusters(obj)
        
        %Fill unallocated regions
        fill_unalloc_regions(obj)
        
        divide_AR_by_best_side(obj,clusterA,clusterB)     
        
        divide_AR_by_SA(obj,clusterA,clusterB)
        
        %Plot IPFmap of clusters found
        genReconstructedIPFmap(obj,filledtype)
        
    end
    
end