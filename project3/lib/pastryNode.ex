def Pastrynode do
    use Genserver
@b 4
 #Generate Node process
    def start(hashid) do
        {:ok,pid} = GenServer.start(__MODULE__,hashid)
        {pid,hashid}
    end

    def init(args) do  
        {:ok,%{:node_id => args}}
    end

    

    def longest_prefix_match(key,hash_id,start_value,longest_prefix_count) do
            if(String.at(key,start_value) == String.at(hash_id,start_value)) do
            longest_prefix_count=longest_prefix_matched(key,hash_id,start_value+1,longest_prefix_count+1)
            end
            longest_prefix_count
        end

    # fetching nearest node for the last case in pastry
    def searchAllForNearestNeighbour(allSet,key,nodeHash,lngth) do
    
    end 


    def findNearestNeighbour(key,length_longest_prefix,c_idx,ncols,row) do
            
    end

    #Get the length of the longest prefix match
    def getLengthLPM(key,hash,start_value,longest_prefix_count) do
        
    end

    #routing table construction
   def constructNodeRouteTable(nodeHash,nodelist,b) do

    end


    def routeTableRows(node_list,rows,cols,r_idx,node_hash,routing_table) do

    end

    def routeTableCols(node_list,rows,cols,r_idx,c_idx,node_hash,substring,routing_table) do

    end

    #Get functions for the routing table column functions for extra flexibility
    def getRoutTableRow(nrows,ncols,list_routing_table,r_idx,c_idx,routing_table) do

    end


    def getRouteTableCol(nrows,ncols,list_routing_table,r_idx,c_idx,routing_table) do

    end


    #calculate the lower leaf set
    def computeLeafLower(list_lower_leaf, idx, list_node , b) do

    end
    
     # calculate the upper leaf set
    def computeLeafUpper(list_upper_leaf, idx,list_node, b) do
        
    end

    #compute neighbor set
    def computeNeighbourSet(start_value,list_node, idx ,neighbor_list) do
       
    end

    def findMatchingSubstrInList(node_list,substring,nodeHash) do

    end

end