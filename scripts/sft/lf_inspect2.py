from llamafactory.hparams.model_args import ModelArguments, AttentionFunction
print("AttentionFunction values:")
for e in AttentionFunction:
    print(f"  {e.name} = '{e.value}'")
