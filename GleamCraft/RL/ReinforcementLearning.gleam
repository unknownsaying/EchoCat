// src/rl_agent/brain/neural_network.gleam
import gleam/list
import gleam/float

pub type Layer {
  Dense(weights: Matrix, biases: Vector, activation: Activation)
  Conv(filters: List(Matrix), biases: Vector, stride: Int)
  LSTM(weight_matrix: Matrix, recurrent_weights: Matrix, biases: Vector)
}

pub type Activation {
  ReLU
  Tanh
  Sigmoid
  Softmax
}

pub type NeuralNetwork {
  NeuralNetwork(
    layers: List(Layer),
    learning_rate: Float
  )
}

pub fn forward_pass(network: NeuralNetwork, input: Tensor) -> Tensor {
  list.fold(
    network.layers,
    input,
    fn(layer, activations) {
      case layer {
        Dense(weights, biases, activation) ->
          let weighted = matrix.multiply(weights, activations)
          let with_bias = vector.add(weighted, biases)
          apply_activation(with_bias, activation)
        
        Conv(filters, biases, stride) ->
          convolve(activations, filters, stride)
          |> vector.add(biases)
        
        LSTM(w, u, b) ->
          lstm_cell(activations, w, u, b)
      }
    }
  )
}

// Experience Replay Buffer
pub type Experience {
  Experience(
    state: State,
    action: Action,
    reward: Float,
    next_state: State,
    done: Bool
  )
}

pub type ReplayBuffer {
  ReplayBuffer(
    buffer: CircularBuffer(Experience),
    capacity: Int,
    batch_size: Int
  )
}

pub fn sample_batch(buffer: ReplayBuffer) -> List(Experience) {
  list.take_random(buffer.buffer, buffer.batch_size)
}