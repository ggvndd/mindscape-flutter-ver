import json

notebook_path = "/Users/gvnd/Documents/Repo/mindscape_flutter/ux_metrics_process.ipynb"

with open(notebook_path, 'r') as f:
    nb = json.load(f)

# Find indices of sections
thesis_md_idx = -1
thesis_code_idx = -1
vis_md_idx = -1

for i, cell in enumerate(nb['cells']):
    if cell['cell_type'] == 'markdown' and len(cell['source']) > 0:
        if 'Thesis-Specific Statistical Workflow' in cell['source'][0]:
            thesis_md_idx = i
        elif '7) Visualize Metric Distributions' in cell['source'][0]:
            vis_md_idx = i

if thesis_md_idx != -1:
    thesis_code_idx = thesis_md_idx + 1

if thesis_md_idx != -1 and vis_md_idx != -1 and thesis_md_idx > vis_md_idx:
    print(f"Moving Thesis section (indices {thesis_md_idx}, {thesis_code_idx}) before Visualization section (index {vis_md_idx})")
    
    # Extract the two cells
    thesis_md = nb['cells'][thesis_md_idx]
    thesis_code = nb['cells'][thesis_code_idx]
    
    # Remove them from their current position (remove code first to not mess up md index)
    nb['cells'].pop(thesis_code_idx)
    nb['cells'].pop(thesis_md_idx)
    
    # Insert them before visualization section
    nb['cells'].insert(vis_md_idx, thesis_code)
    nb['cells'].insert(vis_md_idx, thesis_md)

with open(notebook_path, 'w') as f:
    json.dump(nb, f, indent=1)

print("Notebook reordered successfully.")
