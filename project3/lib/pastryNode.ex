def Pastrynode do
    use Genserver

 #Generate Node process
    def start(node_id,b) do
        hash=:crypto.hash(:sha, to_string(node_id)) |> Base.encode16 |> Convertat.from_base(16) |> Convertat.to_base(b+1)
        {:ok,pid} = GenServer.start(__MODULE__,hash)
        {pid,hash,node_id}
    end

    def init(args) do  
        {:ok,%{:node_id => args}}
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
    def computerLeafUpper(list_upper_leaf, idx,list_node, b) do
        
    end

    #compute neighbor set
    def computerNeighborSet(start_value,list_node, idx ,neighbor_list) do
       
    end

    def findMatchingSubstrInList(node_list,substring,nodeHash) do

    end

end