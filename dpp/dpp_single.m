function [cliq_and_plex, communities] = dpp_single(a, k, m)
%DPP_SINGLE Runs the dynamic plex propogation for one time step.
%   See full details in the dpp(..) function. This function evaluates a
%   single time step to identify cliques, then identifies k-plexes in all
%   vertices that are not part of the cliques. Cliques and k-plexes are 
%   then grouped into communities.
%
%       a
%       Square adjacency matrix with zero diagonal.
%
%       k
%       The largest k when searching for k-plexes. Defaults to 2.
%
%       m
%       The minimum clique or k-plex size. Defaults to k + 2.

% default values
if ~exist('k', 'var') || isempty(k)
    k = 2;
end
if ~exist('m', 'var') || isempty(m)
    m = k + 2;
end

% number of vertices
n = size(a, 1);

% find cliques of size m or larger
cliq = bk(a, m);

% number of cliques
num_cliq = size(cliq, 1);

% all vertices that are connected but not in a clique
vs = [];
already_considered = false(1, n);
for i = 1:(n-1)
    % find vertices that have not yet been considered AND are connected to
    % i AND are not in a clique with i
    already_considered(i) = true; % only looks at vertices > i (since symmetric adjacency)
    connected_to_i = a(i, :);
    in_clique_with_i = any(cliq(cliq(:, i), :));
    j = find(already_considered & connected_to_i & ~in_clique_with_i);
    
    % if found other vertices, add them to our list
    if ~isempty(j)
        vs = [vs i j];
    end
end
vs = sort(unique(vs));

% create a subgraph of connected vertices that are not part of a clique and
% look for k-plexes in this subgraph
sub_a = subgraph(a, vs);
sub_plex = bkplex(sub_a, k, m);

% project the subgraph back to original graph
% vs(..) projects vertices back to original set
plex = false(size(sub_plex, 1), n);
plex(:, vs) = sub_plex;

% append subplexes to cliques
cliq_and_plex = [cliq; plex];

% number of cliques and subplex
num_cliq_and_plex = size(cliq_and_plex, 1);

% to start, everything in a seperate component
communities = 1:num_cliq_and_plex;

% consider pairs of cliques/k-plexes
for i = 1:(num_cliq_and_plex-1)
    for j = (i+1):num_cliq_and_plex
        % count the overlap in vertices between clique/k-plex i and
        % clique/k-plex j
        overlap = sum(and(cliq_and_plex(i, :), cliq_and_plex(j, :)));
        
        % if either one is a clique
        if xor(i <= num_cliq, j <= num_cliq)
            % then the overlap must be greater than m-2
            if overlap >= (m-2)
                % merge into a community
                communities = communities_merge(communities, i, j);
            end
        else
            % otherwise the overlap must be greater than m-1
            if overlap >= (m-1)
                % merge into a community
                communities = communities_merge(communities, i, j);
            end
        end
    end
end

% renumber components in sequential ascending order
communities = communities_renumber(communities);

end
