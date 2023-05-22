#!/usr/bin/env python3

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

sns.set(style="whitegrid")

data = pd.read_json('results/all.json')

# sns.violinplot(data=data, inner="quartile", bw=.2, x='configuration', y="analysis_time")
# plt.show()
sns.violinplot(data=data, inner="quartile", bw=.2, x='configuration', y="total_time")
plt.show()
# sns.violinplot(data=data, inner="quartile", bw=.2, x='configuration', y="total_memory")
# plt.show()
# sns.boxplot(data=data, x='configuration', y="total_time")
# plt.show()

# filtered = data.filter(['setup_time', 'classlist_time', 'analysis_time', 'universe_time', 'compile_time', 'image_time', 'write_time', 'configuration'])
# sns.barplot(data=filtered)
# plt.show()
#
# filtered.set_index('configuration').plot(kind='bar', stacked=True)
# plt.show()