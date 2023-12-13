#Load packages
library(tidyverse)
library(dplyr)
library(nls2)
library(devtools)

#Read the .csv file containing the data
elisa <- read_csv("data/sample_elisa.csv")

# Add the key
key <- read.csv("keys/sample_key.csv")

#Take out only the data, rename columns
ods <- elisa |>
  filter(row_number() %in% (24:40))

colnames(ods)[2:15] = c("row", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, "wavelength")

ods_2 <- select(ods, "row":"wavelength") |>
  relocate("wavelength", .after = row)

#Fill in the N/A values in the first column
ods_2["2", "row"] <- "A"
ods_2["4", "row"] <- "B"
ods_2["6", "row"] <- "C"
ods_2["8", "row"] <- "D"
ods_2["10", "row"] <- "E"
ods_2["12", "row"] <- "F"
ods_2["14", "row"] <- "G"
ods_2["16", "row"] <- "H"

#Tidy
ods_long <- ods_2 |>
  pivot_longer(cols = c(3:14),
               names_to = "column",
               values_to = "optical_density")

# 450-540
subtract_ods <- ods_long |>
  group_by(row, column) |>
  summarise(diff_od = optical_density[wavelength == 450] - optical_density[wavelength== 540])

# Turn "column" into a numeric value
subtract_ods$column <- as.numeric(subtract_ods$column)

# Join key with data
ods_key <- subtract_ods |>
  left_join(key, join_by(column==column, row==row))

# Calculate Average Reagent Dilutent
avg_dilutent <- ods_key |>
  filter(type == "rd") |>
  filter(!is.na(diff_od)) |>
  summarise(dilutent_avg = mean(diff_od))

# Subtract the reagent dilutent from each value
subtract_dilutent <- ods_key |>
  mutate(norm_od = diff_od - avg_dilutent$dilutent_avg)

#Filter out only the standards
find_standards <- subtract_dilutent |>
  filter(type == "standard" & !is.na(standard_conc))


# Michaelis Menten standard curve
mm_form <- formula(norm_od ~ (max.od * standard_conc) / (Km + standard_conc))

mm_mod <- nls2::nls2(mm_form,
                     data=find_standards,
                     start = list(max.od = 3,
                                  Km = 1000))
summary(mm_mod)

grid <- data.frame(standard_conc = seq(from = min(find_standards$standard_conc),
                                       to = max(find_standards$standard_conc),
                                       length.out = 1000))

preds <- predict(mm_mod,
                 newdata = grid)

pred_df <- data.frame(standard_conc = grid,
                      norm_od = preds)

# Standard curve plot
ggplot() +
  geom_point(data = find_standards, aes(x=standard_conc, y=norm_od), color = "#002CFF") +
  geom_line(data = pred_df, aes(x=standard_conc, y=norm_od)) +
  labs(x = "Standard Concentration", y = "Normalized OD") +
  theme_bw()


## STOP HERE #1 ##


# Calculate Macrophage Average
mac_avg <- subtract_dilutent |>
  filter(type == "mac") |>
  summarise(mac.avg = mean(norm_od))

# Subtract the macrophage average from each value
subtract_mac_avg <- subtract_dilutent |>
  mutate(minus_mac = norm_od - mac_avg$mac.avg) |>
  ungroup()


# Apply the Michaelis Menten curve to the samples

# Get only samples
find_samples <- subtract_mac_avg |>
  filter(type == "sample" & !is.na(minus_mac) & !is.na(strain))

#Function to calculate sample concentrations
calc_sample_conc <- function(df, model, OD) {
  # Pull out the max OD and the Km from the model
  max.od <- summary(model)$coefficients["max.od", "Estimate"]
  Km <- summary(model)$coefficients["Km", "Estimate"]

  # Use them to calculate the calibrated function
  conc <- df |>
    mutate(concentration = (OD * Km) / (max.od - OD))
  conc
}

# Apply the function to our samples
samples_conc <- calc_sample_conc(find_samples, mm_mod, find_samples$minus_mac)

view(samples_conc)

## STOP HERE #2 ##

#Make plot

# Find average and standard deviation
average_conc <- mutate(samples_conc,
                       average.conc = mean(concentration),
                       stdev = sd(concentration),
                       .by = "strain") |>
  arrange(average.conc)

labels <- unique(average_conc$strain)

# Make plot
ggplot(average_conc, aes(x = reorder(strain, average.conc), y = average.conc, fill = reorder(strain, average.conc))) +

  #Make bar plot, separated by strain
  geom_bar(stat = "identity", position=position_dodge(width = 0.7), width = 0.6, color = "#777777") +

  scale_color_brewer(palette = "Dark2") +

  #Set colors and legend labels
  scale_fill_discrete(labels = labels) +

  #Set x axis labels
  scale_x_discrete(labels = labels) +

  # Set y axis label and title
  labs(x = "Strain", y = "TNF-α Release", fill = "Strain") +

  #Theme
  theme_bw() +
  theme(panel.background = element_rect(fill = "#F1F8FB"),
        text = element_text(family = "Times New Roman", size = 10),
        legend.text = element_text(family = "Times New Roman", size = 8)) +

  # Add error bars
  geom_errorbar(width = 0.2, color = "#555555",
                aes(ymin = average.conc+stdev, ymax = average.conc-stdev),
                position=position_dodge(width = 0.7)) +

  # Add points
  geom_point(data = average_conc, mapping = aes(x = strain, y = concentration),
             position=position_jitterdodge(jitter.width = 0.4, jitter.height = 0, dodge.width = 0.7),
             size = 0.8,
             #color = "#222222",
             color = "#000000",
             alpha = 1)
