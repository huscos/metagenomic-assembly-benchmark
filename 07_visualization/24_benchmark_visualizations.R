# ==============================================================================
# METAGENOMICS PRESENTATION PLOTS
# ==============================================================================
# Load required libraries
library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)

# ==============================================================================
# 1. LOAD DATA & LOCK X-AXIS ORDER
# ==============================================================================
# Load the 509 Species Representative MAGs
df_winners <- read_tsv("Master_MAG_Summary_Table.tsv") %>%
  mutate(Mode = case_when(
    grepl("Single-sample binning", binning_method) ~ "Single/Single",
    grepl("Multi-sample binning", binning_method) & grepl("Single-sample", assembly_method) ~ "Single/Multi",
    grepl("Co-assembly", assembly_method) ~ "Co/Multi"
  )) %>%
  # This locks the order so it is ALWAYS A -> B -> C on every plot
  mutate(Mode = factor(Mode, levels = c("Single/Single", "Single/Multi", "Co/Multi")))

df_all <- read_csv("Cdb.csv") %>%
  mutate(Mode = case_when(
    grepl("^mB_", genome) ~ "Single/Multi",
    grepl("^mC_", genome) ~ "Co/Multi",
    TRUE ~ "Single/Single" 
  )) %>%
  mutate(Mode = factor(Mode, levels = c("Single/Single", "Single/Multi", "Co/Multi")))

# ==============================================================================
# 2. GLOBAL CONFIGURATION (COLORS & THEMES)
# ==============================================================================
# --- Palette 1: The Three Modes ---
my_mode_colors <- c("Single/Single" = "#f6f7b2",  # Orange
                    "Single/Multi" = "#f283c0",  # Light Blue
                    "Co/Multi" = "#98d6a3")  # Green



# --- Palette 2: The Top Phyla ---
top_15_phyla <- df_winners %>% count(phyla, sort = TRUE) %>% top_n(15, n) %>% pull(phyla)

my_phyla_colors <- c(
  "#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462", 
  "#B3DE69", "#FCCDE5", "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F",
  "#1F78B4", "#33A02C", "#E31A1C", "#B15928" 
)
names(my_phyla_colors) <- c(top_15_phyla, "Other Phyla")

# Clean the dataframe to use the Top
df_winners <- df_winners %>%
  mutate(phyla_clean = ifelse(phyla %in% top_15_phyla, phyla, "Other Phyla")) %>%
  mutate(phyla_clean = factor(phyla_clean, levels = c(top_15_phyla, "Other Phyla")))

# --- Global Theme Definition ---
my_presentation_theme <- theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(b = 10)),
    plot.subtitle = element_text(hjust = 0.5, color = "grey30", margin = margin(b = 15)),
    axis.title.x = element_text(margin = margin(t = 15), face = "bold"),
    axis.title.y = element_text(margin = margin(r = 15), face = "bold"),
    legend.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.minor = element_blank() 
  )

# ==============================================================================
# 3. PLOT 1: THE SCOREBOARD & TAXONOMY (Overall Yield)
# ==============================================================================
totals_overall <- df_winners %>% count(Mode)

plot_overall <- ggplot(df_winners, aes(x = Mode, fill = phyla_clean)) +
  geom_bar(position = "stack", color = "black", width = 0.65, size = 0.3) +
  geom_text(data = totals_overall, aes(x = Mode, y = n, label = n, fill = NULL), 
            vjust = -0.5, size = 7, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = my_phyla_colors, name = "Top Phyla") +
  labs(title = "Species Representative MAGs Recovered by each Pipeline Strategy",
       subtitle = "Total Number Of Species Representative MAGs = 509",
       x = "Pipeline Strategy",
       y = "Number of Species Representative MAGs") +
  my_presentation_theme

print(plot_overall)
ggsave("Slide_1_Overall_Yield.png", plot = plot_overall, width = 11, height = 7, dpi = 300)

# ==============================================================================
# 4. PLOT 2A: COMPLETENESS QUALITY CHECK
# ==============================================================================
plot_completeness <- ggplot(df_winners, aes(x = Mode, y = completeness, fill = Mode)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.size = 2, color = "black") +
  geom_hline(yintercept = 50, linetype = "dashed", color = "#009E73", size = 1.2) +
  annotate("text", x = 1.5, y = 52, label = "Minimum Allowable Completeness (50%)", color = "#009E73", fontface = "italic", size = 3) +
  scale_fill_manual(values = my_mode_colors) +
  labs(title = "Completeness of the Species Representative MAGs by Pipeline Strategy",
       subtitle = "",
       x = "Pipeline Strategy",
       y = "CheckM Completeness (%)") +
  my_presentation_theme +
  theme(legend.position = "none") 

print(plot_completeness)
ggsave("Slide_2A_Completeness.png", plot = plot_completeness, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 5. PLOT 2B: CONTAMINATION QUALITY CHECK
# ==============================================================================
plot_contamination <- ggplot(df_winners, aes(x = Mode, y = contamination, fill = Mode)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.size = 2, color = "black") +
  geom_hline(yintercept = 10, linetype = "dashed", color = "#D55E00", size = 1.2) +
  annotate("text", x = 1.5, y = 10.5, label = "Maximum Allowable Contamination (10%)", color = "#D55E00", fontface = "italic", size = 3) +
  scale_fill_manual(values = my_mode_colors) +
  labs(title = "Contamination of the Species Representative MAGs by Pipeline Strategy",
       subtitle = "",
       x = "Pipeline Strategy",
       y = "CheckM Contamination (%)") +
  my_presentation_theme +
  theme(legend.position = "none") 

print(plot_contamination)
ggsave("Slide_2B_Contamination.png", plot = plot_contamination, width = 8, height = 6, dpi = 300)

# ==============================================================================
# 6. PLOT 3: FRAGMENTATION (Genome Contiguity)
# ==============================================================================
plot_contigs <- ggplot(df_winners, aes(x = Mode, y = Number_of_contigs, fill = Mode)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.size = 2, color = "black") +
  scale_y_log10() + 
  scale_fill_manual(values = my_mode_colors) +
  labs(title = "Fragmentation of the Species Representative MAGs by Pipeline Strategy",
       subtitle = "",
       x = "Pipeline Strategy",
       y = "Number of Contigs (log10)") +
  my_presentation_theme +
  theme(legend.position = "none")

print(plot_contigs)
ggsave("Slide_3_Fragmentation.png", plot = plot_contigs, width = 11, height = 7, dpi = 300)

# ==============================================================================
# 7. PLOT 4: HEAD-TO-HEAD DOMINANCE
# ==============================================================================
shared_clusters <- df_all %>%
  group_by(secondary_cluster) %>%
  filter(any(Mode == "Single/Multi") & any(Mode == "Co/Multi")) %>%
  pull(secondary_cluster) %>% unique()

h2h_data <- df_winners %>% filter(secondary_cluster %in% shared_clusters)
h2h_totals <- h2h_data %>% count(Mode)

# Removed the 'reorder' so the X-axis naturally plots as Single/Single -> B -> C
plot_h2h <- ggplot(h2h_data, aes(x = Mode, fill = phyla_clean)) +
  geom_bar(position = "stack", color = "black", width = 0.65, size = 0.3) +
  geom_text(data = h2h_totals, aes(x = Mode, y = n, label = n, fill = NULL), 
            vjust = -0.5, size = 7, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = my_phyla_colors, name = "Top Phyla") +
  labs(title = "Head-to-Head: Shared Species Outcomes",
       subtitle = "Out of 281 species found by multiple modes, who built the better genome?",
       x = "Pipeline Strategy",
       y = "Number of Direct 1v1 Victories") +
  my_presentation_theme

#print(plot_h2h)
#ggsave("Slide_4_HeadToHead.png", plot = plot_h2h, width = 11, height = 7, dpi = 300)

print("All 5 Presentation Plots Successfully Generated and Saved!")

# ==============================================================================
# 8. PLOT 5: EXCLUSIVE DISCOVERIES (The "Only Found Here" MAGs)
# ==============================================================================
# 1. Figure out how many modes participated in every single cluster
cluster_participation <- df_all %>%
  group_by(secondary_cluster) %>%
  summarize(
    Modes_Present = n_distinct(Mode),
    .groups = "drop"
  )

# 2. Filter the winners to ONLY the ones where exactly ONE mode was present
exclusive_data <- df_winners %>%
  left_join(cluster_participation, by = "secondary_cluster") %>%
  filter(Modes_Present == 1)

# 3. Calculate totals for the numbers on top of the bars
exclusive_totals <- exclusive_data %>% count(Mode)

# 4. Create the Plot
plot_exclusive <- ggplot(exclusive_data, aes(x = Mode, fill = phyla_clean)) +
  geom_bar(position = "stack", color = "black", width = 0.65, size = 0.3) +
  geom_text(data = exclusive_totals, aes(x = Mode, y = n, label = n, fill = NULL), 
            vjust = -0.5, size = 7, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = my_phyla_colors, name = "Top Phyla") +
  labs(title = "Exclusive Species Discoveries by Pipeline Strategy",
       subtitle = "Species discovered by ONE mode that were completely invisible to the others",
       x = "Pipeline Strategy",
       y = "Number of Exclusively Discovered Species") +
  my_presentation_theme

print(plot_exclusive)
ggsave("Slide_5_Exclusive_Discoveries.png", plot = plot_exclusive, width = 11, height = 7, dpi = 300)

# Install the package if you don't have it!
if (!requireNamespace("ggVennDiagram", quietly = TRUE)) {
  install.packages("ggVennDiagram")
}
library(ggVennDiagram)

# ==============================================================================
# PLOT 6: THE SPECIES OVERLAP VENN DIAGRAM
# ==============================================================================
# 1. Extract the lists of every unique species each Mode managed to find 
#    (Before dRep picked the ultimate winners)
clusters_A <- df_all %>% filter(Mode == "Single/Single") %>% pull(secondary_cluster) %>% unique()
clusters_B <- df_all %>% filter(Mode == "Single/Multi") %>% pull(secondary_cluster) %>% unique()
clusters_C <- df_all %>% filter(Mode == "Co/Multi") %>% pull(secondary_cluster) %>% unique()

# 2. Combine them into a list for the Venn package
venn_list <- list(
  "Single/Single" = clusters_A, 
  "Single/Multi" = clusters_B, 
  "Co/Multi" = clusters_C
)

# 3. Create the Venn Diagram
# We use your exact Co/Multiolors for the borders of the circles
plot_venn <- ggVennDiagram(venn_list, 
                           category.names = c("Single/Single", "Single/Multi", "Co/Multi"),
                           set_color = c("#E69F00", "#56B4E9", "#009E73"),
                           label_alpha = 0, # Makes the background of the numbers transparent
                           label_size = 4) +
  # Adds a clean blue gradient based on how many species are in that section
  scale_fill_gradient(low = "#F4FAFE", high = "#4981BF") + 
  labs(title = "Species Detection Overlap Before dRep Filtering",
       subtitle = "How many unique species did each pipeline successfully assemble?",
       caption = "Note: Total distinct species across all three modes = 509") +
  theme_void(base_size = 16) + # theme_void removes the messy gridlines for Venns
  theme(plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(b = 10)),
        plot.subtitle = element_text(hjust = 0.5, color = "grey30", margin = margin(b = 15)),
        plot.caption = element_text(hjust = 0.5, face = "italic"),
        legend.position = "none")

#print(plot_venn)
#ggsave("Slide_4_Venn_Diagram.png", plot = plot_venn, width = 10, height = 8, dpi = 300)

##
# ==============================================================================
# The full comparaison (Including Single/Single)
# ==============================================================================
# 1. Figure out how many modes participated in every single cluster
cluster_participation <- df_all %>%
  group_by(secondary_cluster) %>%
  summarize(
    Modes_Present = n_distinct(Mode),
    .groups = "drop"
  )

# 2. Filter winners to ONLY the clusters where >1 Co/Multiompeted
competitive_clusters <- cluster_participation %>%
  filter(Modes_Present > 1) %>%
  pull(secondary_cluster)

full_h2h_data <- df_winners %>%
  filter(secondary_cluster %in% competitive_clusters)

# 3. Calculate totals for the numbers on top of the bars
full_h2h_totals <- full_h2h_data %>% count(Mode)

# 4. Create the Plot
plot_full_h2h <- ggplot(full_h2h_data, aes(x = Mode, fill = phyla_clean)) +
  geom_bar(position = "stack", color = "black", width = 0.65, size = 0.3) +
  geom_text(data = full_h2h_totals, aes(x = Mode, y = n, label = n, fill = NULL), 
            vjust = -0.5, size = 7, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = my_phyla_colors, name = "Top Phyla") +
  labs(title = "Comparative Performance in Competitive Clusters",
       subtitle = "Outcomes for all species where at least 2 pipelines submitted a genome",
       x = "Pipeline Strategy",
       y = "Number of Competitive Victories") +
  my_presentation_theme

print(plot_full_h2h)
ggsave("Bonus_Plot_Full_HeadToHead.png", plot = plot_full_h2h, width = 11, height = 7, dpi = 300)
