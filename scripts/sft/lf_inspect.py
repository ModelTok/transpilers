from llamafactory.hparams.model_args import ModelArguments
import dataclasses
targets = ["flash_attn", "disable_gradient_checkpointing", "use_reentrant_gc"]
for f in dataclasses.fields(ModelArguments):
    if f.name in targets:
        print(f"name={f.name}  type={f.type}  default={repr(f.default)}")
        if hasattr(f, 'metadata') and f.metadata:
            help_txt = f.metadata.get('help', '')
            if help_txt:
                print(f"  help: {help_txt[:150]}")
