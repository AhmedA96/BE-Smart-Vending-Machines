# frozen_string_literal: true

# Pagy initializer file
# See https://ddnexus.github.io/pagy/api/pagy#configuration

# Default variables
Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:size] = 1

# Enable backend methods
require 'pagy/extras/array'
require 'pagy/extras/metadata'
