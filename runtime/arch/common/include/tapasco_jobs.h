//
// Copyright (C) 2014 Jens Korinth, TU Darmstadt
//
// This file is part of Tapasco (TPC).
//
// Tapasco is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Tapasco is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Tapasco.  If not, see <http://www.gnu.org/licenses/>.
//
//! @file	tapasco_jobs.h
//! @brief	Defines a micro API for threadpool job management.
//! @author	J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
//!
#ifndef TAPASCO_API_JOBS_H__
#define TAPASCO_API_JOBS_H__

#include <tapasco_errors.h>
#include <tapasco_types.h>

#define TAPASCO_JOBS_Q_SZ 250
#define TAPASCO_JOB_MAX_ARGS 32

/** @defgroup common_job common: job struct
 *  @{
 */
/** Possible states of a job. **/
typedef enum {
  /** job is available **/
  TAPASCO_JOB_STATE_READY = 0,
  /** job id has been acquired, but not yet scheduled; accepts args in this
     state **/
  TAPASCO_JOB_STATE_REQUESTED,
  /** job has been scheduled and is awaiting execution, no more changes in this
     state **/
  TAPASCO_JOB_STATE_SCHEDULED,
  /** job is currently executing, no more changes in this state, return value
     instable **/
  TAPASCO_JOB_STATE_RUNNING,
  /** job has finished, return value is valid **/
  TAPASCO_JOB_STATE_FINISHED,
} tapasco_job_state_t;

/** Internal structure for ad-hoc data transfers. **/
struct tapasco_transfer {
  size_t len;
  void *data;
  tapasco_device_alloc_flag_t flags;
  tapasco_copy_direction_flag_t dir_flags;
  tapasco_handle_t handle;
  uint8_t preloaded;
};
typedef struct tapasco_transfer tapasco_transfer_t;

/**
 * Internal job structure to maintain information on an execution to be
 * scheduled some time in the future.
 **/
typedef struct tapasco_jobs tapasco_jobs_t;

/** Initializes the internal jobs struct. */
tapasco_res_t tapasco_jobs_init(tapasco_dev_id_t dev_id, tapasco_jobs_t **jobs);

/** Releases internal jobs struct and associated memory. */
void tapasco_jobs_deinit(tapasco_jobs_t *jobs);

/**
 * Returns the kernel id for the given job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @return kernel id of the kernel this job shall run at.
 **/
tapasco_kernel_id_t tapasco_jobs_get_kernel_id(tapasco_jobs_t const *jobs,
                                               tapasco_job_id_t const j_id);

/**
 * Sets the kernel id for the given job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param k_id kernel id.
 **/
void tapasco_jobs_set_kernel_id(tapasco_jobs_t *jobs,
                                tapasco_job_id_t const j_id,
                                tapasco_kernel_id_t const k_id);

/**
 * Returns the current state of the given job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @return state of the job, see @tapasco_job_state_t.
 **/
tapasco_job_state_t tapasco_jobs_get_state(tapasco_jobs_t const *jobs,
                                           tapasco_job_id_t const j_id);

/**
 * Sets the current state of the given job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param new_state state to set.
 * @return old state.
 **/
tapasco_job_state_t tapasco_jobs_set_state(tapasco_jobs_t *jobs,
                                           tapasco_job_id_t const j_id,
                                           tapasco_job_state_t const new_state);

/**
 * Returns the return value(s) of job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param ret_len number of bytes to copy.
 * @param ret_value pointer to pre-allocated memory to copy data to.
 * @return TAPASCO_SUCCESS, if return values could be copied and are valid.
 **/
tapasco_res_t tapasco_jobs_get_return(tapasco_jobs_t const *jobs,
                                      tapasco_job_id_t const j_id,
                                      size_t const ret_len, void *ret_value);

/**
 * Returns the number of currently prepared arguments in the given job.
 * @param jobs jobs context.
 * @parma j_id job id.
 * @return number of arguments that have been set.
 **/
size_t tapasco_jobs_arg_count(tapasco_jobs_t const *jobs,
                              tapasco_job_id_t const j_id);

/**
 * Returns the 32-bit value of an argument.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument to retrieve.
 * @return value as 32-bit unsigned integer.
 **/
uint32_t tapasco_jobs_get_arg32(tapasco_jobs_t const *jobs,
                                tapasco_job_id_t const j_id,
                                size_t const arg_idx);

/**
 * Returns the 64-bit value of an argument.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument to retrieve.
 * @return value as 64-bit unsigned integer.
 **/
uint64_t tapasco_jobs_get_arg64(tapasco_jobs_t const *jobs,
                                tapasco_job_id_t const j_id,
                                size_t const arg_idx);

/**
 * Returns the transfer struct for the given arg.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument to retrieve.
 * @return pointer to tapasco_transfer_t struct.
 **/
tapasco_transfer_t *tapasco_jobs_get_arg_transfer(tapasco_jobs_t *jobs,
                                                  tapasco_job_id_t const j_id,
                                                  size_t const arg_idx);

/**
 * Returns the value of an argument in a job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument to retrieve.
 * @param arg_len size of argument in bytes.
 * @param arg_value pointer to value data.
 * @return TAPASCO_SUCCESS, if value could be set.
 **/
tapasco_res_t tapasco_jobs_get_arg(tapasco_jobs_t *jobs,
                                   tapasco_job_id_t const j_id,
                                   size_t const arg_idx, size_t const arg_len,
                                   void *arg_value);

/**
 * Sets the value of an argument in a job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument to retrieve.
 * @param arg_len size of argument in bytes.
 * @param arg_value pointer to value data.
 * @return TAPASCO_SUCCESS, if value could be set.
 **/
tapasco_res_t tapasco_jobs_set_arg(tapasco_jobs_t *jobs,
                                   tapasco_job_id_t const j_id,
                                   size_t const arg_idx, size_t const arg_len,
                                   void const *arg_value);

/**
 * Attaches a data transfer to local memory to be run prior to execution of the
 * job. Replaces argument arg_idx with the handle to the address.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument to retrieve.
 * @param arg_len size of argument in bytes.
 * @param arg_value pointer to value data.
 * @param flags transfer flags (see @tapasco_device_alloc_flag_t).
 * @return TAPASCO_SUCCESS, if value could be set.
 **/
tapasco_res_t
tapasco_jobs_set_arg_transfer(tapasco_jobs_t *jobs, tapasco_job_id_t const j_id,
                              size_t const arg_idx, size_t const arg_len,
                              void *arg_value,
                              tapasco_device_alloc_flag_t const flags,
                              tapasco_copy_direction_flag_t const dir_flags);

/**
 * Sets the return value of a job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param ret_len size of return value in bytes.
 * @param ret_value pointer to return value data.
 * @return TAPASCO_SUCCESS, if value could be set.
 **/
tapasco_res_t tapasco_jobs_set_return(tapasco_jobs_t *jobs,
                                      tapasco_job_id_t const j_id,
                                      size_t const ret_len,
                                      void const *ret_value);

/**
 * Helper: Returns true if the given argument is 64-bit value.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param arg_idx index of the argument.
 * @return value != 0 if argument is 64bit, 0 otherwise.
 **/
int tapasco_jobs_is_arg_64bit(tapasco_jobs_t const *jobs,
                              tapasco_job_id_t const j_id,
                              size_t const arg_idx);

/**
 * Returns the assign slot id for this job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @return slot id this job will run on.
 **/
tapasco_slot_id_t tapasco_jobs_get_slot(tapasco_jobs_t const *jobs,
                                        tapasco_job_id_t const j_id);

/**
 * Assigns the slot id for this job.
 * @param jobs jobs context.
 * @param j_id job id.
 * @param slot_id slot to assign.
 **/
void tapasco_jobs_set_slot(tapasco_jobs_t *jobs, tapasco_job_id_t const j_id,
                           tapasco_slot_id_t const slot_id);

/**
 * Reserves a job id for preparation.
 * @param jobs jobs context.
 * @return job id.
 **/
tapasco_job_id_t tapasco_jobs_acquire(tapasco_jobs_t *jobs);

/**
 * Releases a previously acquired job id for re-use.
 * @param jobs jobs context.
 * @param j_id job id.
 **/
void tapasco_jobs_release(tapasco_jobs_t *jobs, tapasco_job_id_t const j_id);

#endif /* TAPASCO_API_JOBS_H__ */
