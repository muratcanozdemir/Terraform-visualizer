class TerraformStateParser:
    def __init__(self, state: Dict[str, Any]):
        self.resources = state['resources']
        self.graph = self._build_resource_graph()

    def _build_resource_graph(self) -> Dict[str, Dict[str, list]]:
        graph = {}
        for resource in self.resources:
            for instance in resource.get('instances', []):
                attributes = instance.get('attributes', {})
                resource_id = attributes.get('id', resource['name'])
                parent_id = attributes.get('parent_id')
                
                if resource_id not in graph:
                    graph[resource_id] = {'parents': [], 'children': []}
                
                if parent_id:
                    graph[resource_id]['parents'].append(parent_id)
                    if parent_id not in graph:
                        graph[parent_id] = {'parents': [], 'children': []}
                    graph[parent_id]['children'].append(resource_id)
        
        return graph

    def get_lineage(self, resource_id: str) -> Dict[str, list]:
        lineage = {'ancestors': [], 'descendants': []}
        visited = set()
        
        # Collect ancestors
        current = resource_id
        while current:
            lineage['ancestors'].append(current)
            visited.add(current)
            parents = self.graph.get(current, {}).get('parents')
            current = parents[0] if parents else None
        
        # Collect descendants using BFS
        queue = [resource_id]
        while queue:
            current = queue.pop(0)
            if current not in visited:
                lineage['descendants'].append(current)
                visited.add(current)
                children = self.graph.get(current, {}).get('children', [])
                queue.extend(children)
        
        return lineage