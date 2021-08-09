#ifndef __SIM_MODEL_H
#define __SIM_MODEL_H

#include <cstdint>

typedef struct sim_model sim_model_t;

sim_model_t* sim_create(int argc, char **argv);
void sim_destroy(sim_model_t* model);
void sim_tick(sim_model_t* model);
void sim_draw(sim_model_t* model);

#endif
