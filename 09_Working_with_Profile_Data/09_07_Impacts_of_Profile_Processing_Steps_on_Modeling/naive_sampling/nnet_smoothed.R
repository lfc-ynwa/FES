library(caret)
library(recipes)

# ------------------------------------------------------------------------------

load("../../../Data_Sets/Pharmaceutical_Manufacturing_Monitoring/smoothed.RData")


# ------------------------------------------------------------------------------

rec <- 
  recipe(Glucose ~ ., data = small_smoothed) %>% 
  update_role(Reactor, new_role = "ID") %>% 
  step_center(all_predictors()) %>% 
  step_scale(all_predictors()) %>%
  step_corr(all_predictors(), threshold = .75) %>%
  step_nzv(all_predictors())

# ------------------------------------------------------------------------------

ctrl <- trainControl(method = "cv",
                     search = "random",
                     savePredictions = TRUE)

# ------------------------------------------------------------------------------
options(keras.fit_verbose = 0)

set.seed(3523)
mod_fit <- 
  train(
    rec, 
    data = small_smoothed,
    method = "mlpKerasDecay",
    tuneLength = 50,
    trControl = ctrl,
    epochs = 100
  )

test_pred <- 
  large_smoothed %>% 
  mutate(Predicted = predict(mod_fit, large_smoothed)) %>% 
  dplyr::select(Predicted, Glucose, Reactor, Day)

# Trim model objects to make smaller -------------------------------------------

mod_fit$recipe$template <- NULL
n_steps <- length(mod_fit$recipe$steps)
for (i in 1:n_steps) {
  n_terms <- length(mod_fit$recipe$steps[[i]]$terms)
  for (j in 1:n_terms)
    attr(mod_fit$recipe$steps[[i]]$terms[[j]], ".Environment") <- emptyenv()
}
mod_fit$control$index <- NULL
mod_fit$control$indexOut <- NULL

# ------------------------------------------------------------------------------

model <- "neural net"
predictors <- "smoothed"

save(mod_fit, test_pred, model, predictors, file = "nnet_smoothed.RData")

# ------------------------------------------------------------------------------

sessionInfo()

# ------------------------------------------------------------------------------

if (!interactive())
  q("no")

