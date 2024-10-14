import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import matplotlib.colors as colors

class PixelStructureSimulation:
    def __init__(self, grid_size, num_structures, merge_rate, separate_rate, neighbor_range):
        self.grid_size = grid_size
        self.num_structures = num_structures
        self.merge_rate = merge_rate
        self.separate_rate = separate_rate
        self.neighbor_range = neighbor_range
        self.grid = np.zeros((grid_size, grid_size), dtype=int)
        self.structures = {}
        self.next_id = 1
        self.initialize_structures()

    def initialize_structures(self):
        for _ in range(self.num_structures):
            x, y = np.random.randint(0, self.grid_size, 2)
            while self.grid[x, y] != 0:
                x, y = np.random.randint(0, self.grid_size, 2)
            self.create_structure(x, y)

    def create_structure(self, x, y):
        self.grid[x, y] = self.next_id
        self.structures[self.next_id] = set([(x, y)])
        self.next_id += 1

    def get_neighbors_in_range(self, x, y):
        neighbors = set()
        for dx in range(-self.neighbor_range, self.neighbor_range + 1):
            for dy in range(-self.neighbor_range, self.neighbor_range + 1):
                if dx == 0 and dy == 0:
                    continue  # Skip the cell itself
                nx, ny = x + dx, y + dy
                if 0 <= nx < self.grid_size and 0 <= ny < self.grid_size:
                    neighbor_id = self.grid[nx, ny]
                    if neighbor_id != 0:
                        neighbors.add(neighbor_id)
        return neighbors

    def merge_structures(self):
        num_merges = np.random.poisson(self.merge_rate)
        merged = set()
        
        for _ in range(num_merges):
            if len(self.structures) < 2:
                break
            
            structure_ids = list(self.structures.keys())
            structure_id = np.random.choice(structure_ids)
            
            if structure_id in merged:
                continue
            
            structure = self.structures[structure_id]
            neighbors = set()
            
            for x, y in structure:
                neighbors.update(self.get_neighbors_in_range(x, y))
            
            neighbors.discard(structure_id)  # Remove self from neighbors
            
            if neighbors:
                neighbor_id = np.random.choice(list(neighbors))
                self.structures[structure_id].update(self.structures[neighbor_id])
                for x, y in self.structures[neighbor_id]:
                    self.grid[x, y] = structure_id
                del self.structures[neighbor_id]
                merged.add(structure_id)
    '''
    def separate_structures(self):
        num_separations = np.random.poisson(self.separate_rate)
        for _ in range(num_separations):
            if len(self.structures) == 0:
                break
            structure_id = np.random.choice(list(self.structures.keys()))
            if len(self.structures[structure_id]) > 1:
                x, y = np.random.choice(list(self.structures[structure_id]))
                self.structures[structure_id].remove((x, y))
                self.create_structure(x, y)
    '''
    def update(self):
        self.merge_structures()
        #self.separate_structures()
        return self.grid, len(self.structures)

def animate(frame, sim, im, title, updates_per_frame):
    for _ in range(updates_per_frame):
        grid, num_structures = sim.update()
    im.set_array(grid)
    title.set_text(f"Frame {frame + 1}, Structures: {num_structures}")
    return [im, title]

def run_simulation(grid_size=50, num_structures=20, merge_rate=2, separate_rate=1, neighbor_range=2, 
                   num_frames=200, updates_per_frame=5, output_file='pixel_structure_simulation.gif'):
    sim = PixelStructureSimulation(grid_size, num_structures, merge_rate, separate_rate, neighbor_range)
    
    fig, ax = plt.subplots(figsize=(10, 10))
    cmap = plt.get_cmap('viridis')
    norm = colors.Normalize(vmin=0, vmax=sim.next_id)
    im = ax.imshow(sim.grid, animated=True, cmap=cmap, norm=norm)
    plt.colorbar(im)
    title = ax.set_title("Pixel Structure Simulation")
    
    anim = FuncAnimation(fig, animate, frames=num_frames, 
                         fargs=(sim, im, title, updates_per_frame),
                         interval=200, blit=True, repeat=False)
    
    # Save the animation as a gif
    anim.save(output_file, writer='pillow', fps=5)
    plt.close(fig)
    print(f"Animation saved as {output_file}")

if __name__ == "__main__":
    run_simulation(grid_size=50, num_structures=100, merge_rate=2, separate_rate=1, 
                   neighbor_range=2, num_frames=10, updates_per_frame=1)